ENV['RACK_ENV'] = 'test'

require_relative '../todos'
require 'rspec'
require 'rack/test'

RSpec.describe TodosApp do
  include Rack::Test::Methods

  def app
    TodosApp
  end

  after do
    Todo.destroy_all
  end

  context 'GET /api/todos' do
    it "responds with JSON of all todos when present" do
      ['Buy Milk', 'Homework', 'Call Mom'].each do |title|
        Todo.create({title: title})
      end

      get '/api/todos'
      expect(last_response).to be_ok
      expect(last_response.body).to eq(Todo.all.to_json)
    end

    it "responds with empty Array JSON when no todos present" do
      get '/api/todos'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('[]')
    end
  end

  context 'GET /api/todos/:id' do
    let(:todo) { Todo.create title: 'Homework' }
    it 'responds with JSON representation of todo with id == :id' do
      get "/api/todos/#{todo.id}"
      expect(last_response).to be_ok
      expect(last_response.body).to eq(todo.to_json)
    end

    # it 'responds with 404 when todo is not found' do
    #   get "/api/todos/#{todo.id + 1}"
    #   expect(last_response.status).to eq(404)
    #   expect(last_response.body).to eq("There's no todo with id = 4")
    # end
  end

  context 'POST /api/todos' do
    let(:valid_todo) { {title: 'Sending emails'} }
    let(:invalid_todo) { { completed: false } }

    it 'adds a todo to the database when todo is valid' do
      post '/api/todos', valid_todo
      expect(Todo.count).to eq(1)
    end

    it 'does not add a todo when the todo is invalid' do
      post '/api/todos', invalid_todo
      expect(Todo.count).to eq(0)
    end

    it 'responds with 400 when the todo is invalid' do
      post '/api/todos', invalid_todo
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('Todo cannot be saved')
    end
  end

  context 'PUT /api/todo/:id' do
    let(:todo) { Todo.create(title: 'Sending emails') }
    it 'updates todo when attributes are valid' do
      put "/api/todos/#{todo.id}", {title: 'Sending report'}
      expect(Todo.first.title).to eq('Sending report')
    end

    it 'does not update the todo when attributes are invalid' do
      put "/api/todos/#{todo.id}", {title: 'S'}
      expect(Todo.first.title).to eq('Sending emails')
    end

    it 'responds with a 400 when attributes are invalid' do
      put "/api/todos/#{todo.id}", {title: 'Hello', month: '123'}
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('Todo cannot be updated.')
    end
  end

  context 'POST /api/todos/:id/toggle_completed' do
    let(:incomplete_todo) { Todo.create(title: 'Sending Email', completed: false) }
    let(:completed_todo) { Todo.create(title: 'Sending Email', completed: true)}

    it 'marks a todo completed when the todo with given id is not completed' do
      post "/api/todos/#{incomplete_todo.id}/toggle_completed"
      expect(Todo.first.completed).to eq(true)
    end

    it 'it marks a todo incomplete when it is already completed' do
      post "/api/todos/#{completed_todo.id}/toggle_completed"
      expect(Todo.first.completed).to eq(false)
    end
  end
end
