require_relative '../lib/todo'

Todo.destroy_all

Todo.create(title: 'Todo 1', completed: false);
Todo.create(title: 'Todo 2', month: "01", day: '01', year: '2018')
Todo.create(title: 'Todo 3', completed: true)
