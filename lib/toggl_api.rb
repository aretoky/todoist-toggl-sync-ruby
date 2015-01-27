class TogglApi
  BASE_URL = 'https://www.toggl.com'
  BASE_PATH = '/api/v8'

  def initialize

  end

  def get(path, data = {})
    @conn.get(BASE_PATH + path, data).body
  end

  def post(path, data = {})
    @conn.post(BASE_PATH + path, data).body
  end

  def login(username, password = 'api_token')
    @conn = Faraday.new(url: BASE_URL, ssl: {verify: false}) do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
      faraday.headers = { "Content-Type" => "application/json"  }
      #faraday.response :logger
      faraday.response  :json, content_type: /\bjson$/
      faraday.basic_auth username, password
    end
  end

  def get_data
    data = {
      'projects' => {}
    }
    raw = self.get('/me?with_related_data=true')['data']
    projects = raw['projects'] || []
    projects.each do |project|
      project['time_entries'] = []
      data['projects'][project['id']] = project
    end
    entries = raw['time_entries'] || []
    entries.each do |entry|
      next  unless entry['pid']
      data['projects'][entry['pid']]['time_entries'] << entry
    end
    data
  end

  def create_project(name)
    p "Create new project" + name
    data = {
      'project' => {
        'name' => name
      }
    }
    data = self.post('/projects', data.to_json)

    project = data['data']
    project['time_entries'] = []
    project
  end

  def update_project(id, data)
    data = {  'project' => data }
    self.post('/projects/' + id, data.to_json)
  end

  def create_time_entry(description, duration, pid, start = nil)
    start = start || Time.now.iso8601# + 'Z'

    data = {
      'time_entry' => {
        'description' => description,
        'duration' => duration,
        'start' => start,
        'pid' => pid,
        'created_with' => 'API'
      }
    }
    ap data = self.post('/time_entries', data.to_json)
    entry = data['data']
  end

  def sync_todoist_data(todo_data)
    p "Syncing toggl with todoist data."
    data = self.get_data
    todo_data['projects'].each do |todo_project|
      self.sync_project(todo_project, data)
    end
  end

  def sync_project(todo_project, data)
    p "Syncing project " + todo_project['name']

    toggl_project = data['projects'].map { |id, proj|
      proj if proj['name'] == todo_project['name']
    }.compact

    project = 0 < toggl_project.size ? toggl_project[0] : self.create_project(todo_project['name'])
    if todo_project['is_archived'].present? == project['archive'].present?
      self.update_project(project['id'], {  'active' => todo_project['is_archived'].blank?  })
    end

    self.sync_tasks(project, data, todo_project['tasks'])
  end

  def sync_tasks(project, data, tasks)
    tasks.each do |task|
      entries = project['time_entries'].map { |e|
        e if e['description'] == task['content']
      }.compact
      if 0 == entries.size
        p "Creating time entry '#{task['content']}' for project '#{project['name']}'"
        self.create_time_entry(task['content'], 0, project['id'])
      end
      if task['children']
        self.sync_tasks(project, data, task['children'])
      end
    end
  end

end