class Syncer
  def initialize
    @todoist = TodoistApi.new
    @toggl = TogglApi.new
  end

  def set_credentials(todoist_token, toggl_token)
    @todoist.login(todoist_token)
    @toggl.login(toggl_token)
  end

  def sync
    todoist_data = @todoist.get_data
    @toggl.sync_todoist_data(todoist_data)
  end
end