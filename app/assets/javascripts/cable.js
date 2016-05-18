//= require action_cable
//= require_self
//= require_tree ./cable
 
(function() {
  this.App || (this.App = {});
 
  App.cable = ActionCable.createConsumer();
}).call(this);