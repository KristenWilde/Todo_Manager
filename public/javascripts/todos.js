class Todo {
  constructor(data) {
    this.update(data);
    this.getDisplayDate();
  }

  update(data) {
    for (let property in data) {
      this[property] = data[property];
    }
    this.getDisplayDate();
  }

  getDisplayDate() {
    if (this.month && this.year) {
      this.displayDate = this.month + '/' + this.year.substr(2,2);
    } else {
      this.displayDate = 'No Due Date';
    }
  }
}

class TodoCollection {
  constructor(heading, todoArray=[], listId) {
    this.heading = heading;
    this.todos = todoArray;
    this.listId = listId || heading;
    this.updateCount();
  }

  updateCount() {
    this.count = this.todos.length
  }

  reset() {
    while (this.todos.length > 0) {
      this.todos.pop();
    }
  }

  add(todo) {
    this.todos.push(todo);
    this.updateCount();
  }

  find(id) {
    return this.todos.filter( todo => {
      return todo.id == id;
    })[0]
  }

  sortedTodos() {
    return this.incompleteTodos().concat(this.completedTodos());
  }

  completedTodos() {
    return this.todos.filter( todo => todo.completed );
  }

  incompleteTodos() {
    return this.todos.filter( todo => !todo.completed );
  }

  displayDates() {
    const displayDates = [];
    this.todos.forEach( todo => {
      if (!displayDates.includes(todo.displayDate)) {
        displayDates.push(todo.displayDate);
      }
    });
    return displayDates.sort( (date1, date2) => {
      if (date1.substr(3,2) + date1.substr(0,2) <= date2.substr(3,2) + date2.substr(0,2)) {
        return -1;
      } else {
        return 1;
      }
    });
  }
}

class TodoApp {
  constructor() {
    this.buildTemplates();
    this.listsByMonth = [];
    this.completedListsByMonth = [];
    this.allTodos = new TodoCollection('All Todos');
    this.activeList = this.allTodos;
    this.getTodos()

    $('#add_new').click(this.showCreateForm.bind(this));
    $('#todos').on('click', '.item a', this.showEditForm.bind(this));
    $('#todos').on('click', '.delete', this.deleteTodo.bind(this));
    $('#todos').on('click', '.item', this.toggleComplete.bind(this));
    $('#overlay').click(this.closeModal.bind(this));
    $('#save').click(this.saveTodo.bind(this));
    $('#mark_complete').click(this.markComplete.bind(this));
    $('nav').on('click', 'tr', this.showList.bind(this));
  }

  buildTemplates() {
    this.templates = {};

    $('script[type="text/x-handlebars"]').each((i, template) => {
      this.templates[template.id] = Handlebars.compile(template.innerHTML);
    });

    $('[data-type=partial]').each((i, partial) => {
      Handlebars.registerPartial(partial.id, partial.innerHTML);
    })
  }

  getTodos() {
    $.ajax({
      method: 'GET',
      url: '/api/todos',
      dataType: 'json',
      success: this.processData.bind(this),
    })
  }

  processData(jsonCollection) {
    this.allTodos.reset();

    jsonCollection.forEach( data => {
      this.allTodos.add(new Todo(data));
    })

    this.sortByDateAndCompletion();
    this.renderNav();
    this.renderList(this.activeList);
  }

  sortByDateAndCompletion() {
    const dueDates = this.allTodos.displayDates();
    this.listsByMonth = dueDates.map( dueDate => this.createTodoCollection(dueDate) );
    this.updateCompletedLists();
  }

  createTodoCollection(dueDate) {
    const todoArray = this.allTodos.todos.filter( todo => {
      return todo.displayDate === dueDate;
    });
    return new TodoCollection(dueDate, todoArray);
  }

  updateCompletedLists() {
    let completedTodos = this.allTodos.completedTodos();
    this.allCompletedTodos = new TodoCollection('Completed', completedTodos);

    this.completedListsByMonth = [];
    this.listsByMonth.forEach( list => {
      completedTodos = list.completedTodos();
      if (completedTodos.length > 0) {
        const newList = new TodoCollection(list.heading, completedTodos, list.heading + '-c');
        this.completedListsByMonth.push(newList);
      }
    })
  }

  renderNav() {
    $('#total_count').text(this.allTodos.count);
    $('#todos_by_date').html(this.templates.navBody(this.listsByMonth));
    $('#total_completed').text(this.allCompletedTodos.count);
    $('#completed_by_date').html(this.templates.navBody(this.completedListsByMonth));
  }

  renderList(collection) {
    $('#todos').html(this.templates.todoCollection(collection.sortedTodos()));
    $('main h1').text(collection.heading);
    $('main .num-todos').text(collection.count);
  }

  deleteTodo(e) {
    const id = $(e.target).closest('[data-id]').attr('data-id');
    $.ajax({
      type: 'DELETE',
      url: '/api/todos/' + id,
      success: this.getTodos.bind(this),
    })
  }

  toggleComplete(e) {
    const id = e.target.getAttribute('data-id');
    $.ajax({
      type: 'POST',
      url: `/api/todos/${id}/toggle_completed`,
      dataType: 'json',
      success: json => {
        this.allTodos.find(id).update(json);
        this.updateCompletedLists();
        this.renderList(this.activeList);
        this.renderNav();
      }
    })
  }

  showCreateForm(e) {
    e.preventDefault();
    $('#modal').fadeIn();
  }

  showEditForm(e) {
    e.preventDefault();
    e.stopPropagation();
    const id = e.target.parentElement.getAttribute('data-id');
    const todo = this.allTodos.find(id);
    this.fillValuesToEdit(todo);

    $('#modal').fadeIn();
  }

  fillValuesToEdit(todo) {
    const $inputs = $('#modal').find('[name]');

    $inputs.each( (i, input) => {
      console.log(input.name)
      input.value = todo[input.name] || "";
    })
  }

  markComplete(e) {
    const id = e.target.value;
    if (!id) {
      alert('Cannot mark as complete as item has not been created yet!');
    }
    else {
      $.ajax({
        type: 'PUT',
        url: '/api/todos/' + id,
        data: "completed=true",
        success: () => {
          this.getTodos();
          $('#modal form')[0].reset();
          $('#modal').fadeOut();
        }
      })
    }
  }

  saveTodo(e) {
    // e.preventDefault();
    const id = e.target.value || null;
    const $form = $('#modal form')

    $.ajax({
      type: id ? 'PUT' : 'POST',
      url: id ? '/api/todos/' + id : '/api/todos',
      data: $form.serialize(),
      success: () => {
        this.getTodos();
        $form[0].reset();
        $('#modal').fadeOut();
      }
    })
  }

  closeModal(e) {
    $('#modal form')[0].reset();
    $('#modal').fadeOut();
  }

  showList(e) {
    e.preventDefault();
    const $tr = $(e.target).closest('tr');
    console.log($tr);
    const listId = $tr.attr('data-list');

    $('tr').removeClass('active');
    $tr.addClass('active');

    this.activeList = this.findList(listId);
    this.renderList(this.activeList);
  }

  findList(listId) {
    const allLists = this.completedListsByMonth
      .concat(this.listsByMonth, this.allTodos, this.allCompletedTodos);
    console.log(allLists);
    return allLists.filter( list => list.listId === listId )[0];
  }



}