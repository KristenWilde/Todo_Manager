require 'pry'
require 'sinatra/base'
require 'sinatra/contrib'
require 'docdsl'
require 'sinatra/activerecord'
require_relative 'lib/todo'

class TodosApp < Sinatra::Base
  register Sinatra::Contrib
  register Sinatra::DocDsl

  set :database_file, "config/database.yml"

  after do
    ActiveRecord::Base.clear_active_connections!
  end

  get '/' do
    send_file File.expand_path('index.html', settings.public_folder)
  end

  namespace '/api' do
    helpers do
      def extract_todo_params()
        todo_params = [:title, :day, :month, :year, :description, :completed]
        params.select { |key, _| todo_params.include?(key.to_sym) }
      end
    end

    documentation 'Retreive all todos.' do
      response 'JSON: all todos.',
        [
          {id: 1, title: 'todo1', day: '11', month: '11',
             year: '2017', completed: true, description: 'Some Description'},
          {id: 2, title: 'todo2', day: nil, month: nil ,
             year: nil, completed: false, description: nil}
        ]
    end
    get '/todos' do
      json Todo.all
    end

    documentation 'Retrieves todo with id = {id}' do
      param :id, 'The id of the requested todo.'
      response 'JSON: the todo',
        {id: 1, title: 'todo 1', day: '11', month: '11', year: '2017', completed: true}
      status 200, 'When todo with id = {id} is found.'
      status 404, 'When todo is not found. Body: "There is no todo with id = {id}"'
    end
    get '/todos/:id' do
      todo = Todo.find_by(id: params[:id])
      if todo
        json todo
      else
        halt 404, "There's no todo with id = #{params[:id]}"
      end
    end

    documentation 'Saves a new todo.' do
      payload "Request payload can be either json or a query string",
        {
          title: 'String (Required) : The todo title. At least three characters long.',
          month: 'String : Format mm. Not saved if format is incorrect',
          day: 'String : Format dd. Not saved if format is incorrect',
          year: 'String : Format yyyy. Not saved if format is incorrect',
          description: 'String : Description of the todo)',
          completed: 'Boolean : Completion status of todo. Will default to false for new todo'
        }
      response 'JSON: The newly created todo with an id attribute',
        {id: 1, title: 'todo 1', day: '11', month: '11', year: '2017', completed: true}
      status 201, 'When the todo is saved'
      status 400, 'When todo cannot be saved (due to incorrect attributes). Body: "Todo cannot be saved"'
    end
    post '/todos' do
      todo_attrs = extract_todo_params
      todo_attrs[:completed] ||= false
      new_todo = Todo.new(extract_todo_params)
      if new_todo.save
        status 201
        json new_todo
      else
        halt 400, 'Todo cannot be saved'
      end
    end

    documentation 'Updates a todo. Uses key/value pairs sent via POST to set attributes of the todo. If key/value pair is not present, its previous value is preserved' do
      payload "Request payload can be either json or a query string",
        {
          title: 'String : The todo title. At least 3 characters long',
          month: 'String : Format mm. Not saved if format is incorrect',
          day: 'String : Format dd. Not saved if format is incorrect',
          year: 'String : Format yyyy. Not saved if format is incorrect',
          description: 'String : Description of the todo)',
          completed: 'Boolean : Completion status of todo. Will default to false for new todo'
        }
      response 'JSON: The updated todo'
      status 201, 'When todo is saved'
      status 400, 'When todo cannot be saved or todo with given id does not exist. Body: "Todo cannot be updated."'
    end
    put '/todos/:id' do
      todo = Todo.find_by(id: params[:id])

      if todo && todo.update_attributes(extract_todo_params)
        status 201
        json todo
      else
        halt 400, 'Todo cannot be updated.'
      end
    end

    documentation 'Deletes a todo' do
      status 204, '204 with no body when todo is deleted'
      status 400, 'When todo with id = {id} does not exist. Body: "Todo does not exist"'
    end
    delete '/todos/:id' do
      todo = Todo.find_by(id: params[:id])
      if todo.nil?
        halt 400, 'Todo does not exist'
      else
        todo.destroy
        halt 204
      end
    end

    documentation 'Toggles a todo completed. If todo with id = {id} has completed = true, it is set to false and vice versa' do
      response "JSON: the updated todo"
      status 201, "When todo is deleted"
      status 400, "When todo with id = {id} cannot be found"
    end
    post '/todos/:id/toggle_completed' do
      todo = Todo.find(params[:id])
      todo.completed = !todo.completed
      if todo.save
        status 201
        json todo
      else
        halt 400, 'Todo cannot be updated'
      end
    end
  end

  doc_endpoint '/doc'
  run! if app_file == $0
end
