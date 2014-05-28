$(document).ready(function() {
  player_hits();
  player_stays();
  dealer_hits();

});

function player_hits() {
  $(document).on("click", "form#hit button", function() {

    $.ajax({
      type: "POST",
      url: "/game/player/hit"
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
};

function player_stays() {
  $(document).on("click", "form#stay button", function() {

    $.ajax({
      type: "POST",
      url: "/game/player/stay"
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
};

function dealer_hits() {
  $(document).on("click", "form#dealers_turn button", function() {

    $.ajax({
      type: "POST",
      url: "/game/dealer_hit"
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
};