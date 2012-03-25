(function() {
  var random_choice, random_color;

  random_choice = function(array) {
    return array[Math.floor(Math.random() * array.length)];
  };

  random_color = function() {
    return [Math.random() * 255, Math.random() * 255, Math.random() * 255];
  };

}).call(this);
