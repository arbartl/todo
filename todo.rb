require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def list_complete?(list)
    todos_count(list) > 0 &&
    todos_remaining_count(list) == 0
  end

  def list_class(list)
    return "complete" if list_complete?(list)
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def todos_count(list)
    list[:todos].size
  end

  def sort_lists(lists, &block)
    complete, incomplete = lists.partition { |list| list_complete?(list) }

    incomplete.each { |list| block.call(list, lists.index(list)) }
    complete.each { |list| block.call(list, lists.index(list)) }
  end

  def sort_todos(todos, &block)
    complete, incomplete = todos.partition { |todo| todo[:completed] }

    incomplete.each { |todo| block.call(todo, todos.index(todo)) }
    complete.each { |todo| block.call(todo, todos.index(todo)) }
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists/new" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else    
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list '#{list_name}' has been successfully created!"
    redirect "/lists"
  end
end

# Return error message if the list name is invalid or nil if valid
def error_for_list_name(list_name)
  if !(1..100).cover? list_name.size
    return "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == list_name }
    return "List name must be unique."
  else
    nil
  end
end

get "/lists/:id" do
  @list = session[:lists][params["id"].to_i]
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  @list = session[:lists][params["id"].to_i]
  erb :edit_list, layout: :layout
end

# Update name of an existing list
post "/lists/:id/edit" do
  list_name = params[:list_name].strip
  @list = session[:lists][params["id"].to_i]

  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else    
    @list[:name] = list_name
    session[:success] = "The list '#{list_name}' has been successfully updated!"
    redirect "/lists/#{params["id"]}"
  end
end

# Delete a list from the list of lists
post "/lists/:id/delete" do
  session[:lists].delete_at(params["id"].to_i)
  session[:success] = "The list was successfully deleted."
  redirect "/lists"
end

# Complete a todo item in a list
post "/lists/:id/todos/:todo_id" do
  id = params[:id].to_i
  @list = session[:lists][id]

  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed

  session[:success] = "The todo item has been updated."
  redirect "/lists/#{id}"
end

# Add a todo item to a list
post "/lists/:id/todos" do
  id = params[:id].to_i
  @list = session[:lists][id]
  todo = params[:todo].strip

  error = error_for_todo(todo)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo, completed: false }
    session[:success] = "'#{params[:todo]}' successfully added!"
    redirect "/lists/#{params["id"]}"
  end
end

def error_for_todo(todo)
  if !(1..100).cover? todo.size
    return "Todo Item must be between 1 and 100 characters."
  else
    nil
  end
end

# Delete a todo item from a list
post "/lists/:id/todos/:todo_id/delete" do
  id = params[:id].to_i
  @list = session[:lists][id]
  todo_id = params[:todo_id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = "The item was successfully deleted."
  redirect "/lists/#{id}"
end



# Complete all items in a list
post "/lists/:id/complete_all" do
  id = params[:id].to_i
  @list = session[:lists][id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todo items completed successfully."
  redirect "/lists/#{id}"
end