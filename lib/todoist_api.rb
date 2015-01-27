class TodoistApi
  BASE_URL = 'https://api.todoist.com'
  API_PATH = '/API'
  LOGIN_PATH = API_PATH + '/login'
  SYNC_PATH = '/TodoistSync/v5.3/get'

  def initialize
    @email = nil
    @password = nil
    @token = nil
    @conn = Faraday.new(url: BASE_URL) do |faraday|
      faraday.request :url_encoded
      #faraday.response  :logger
      faraday.adapter Faraday.default_adapter
      faraday.response :json, content_type: /\bjson$/
    end
  end

  def login(email, password = 'api_token')
    if password == 'api_token'
      @token = email
      return
    end

    @email = email
    @password = password

    response = @conn.post LOGIN_PATH, {email: email, password: password}
    data = response.body
    if data == 'LOGIN_ERROR'

    end
    @token = data['api_token']
  end

  def get_data
    data = {
      'projects' => []
    }
    todo_data = @conn.post(SYNC_PATH, { 'api_token' => @token, 'seq_no' => 0}).body

    project_id_map = {}

    last_project_by_indent = {}

    projects = todo_data['Projects'].sort{ |a, b| a['item_order'] <=> b['item_order']}
    projects.each do |project|
      next  if project['name'] == 'Inbox'

      project['children'] = []
      project['tasks'] = []
      project_id_map[project['id']] = project

      if project['indent'] > 1
        last = last_project_by_indent[project['indent'] - 1]
        last['children'] << project
      else
        data['projects'] << project
      end
      last_project_by_indent[project['indent']] = project
    end

    tasks = todo_data['Items'].sort{  |a, b|  "#{a['project_id']}#{a['item_order']}" <=> "#{b['project_id']}#{b['item_order']}"}

    last_task_by_indent = {}
    tasks.each do |task|
      task['children'] = []

      if task['indent'] > 1
        last = last_task_by_indent[task['indent'] - 1]
        last['children'] << task
      else
        project_id_map[task['project_id']]['tasks'] << task
      end

      last_task_by_indent[task['indent']] = task
    end

    data
  end

end