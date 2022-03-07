require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
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