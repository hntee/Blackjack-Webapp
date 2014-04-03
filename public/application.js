// window.onload = function() {
// 	alert('s')
// }

$(document).ready(function(){
	playerHit();
	playerStay();
	dealerHit();
});

function playerHit() {
	$(document).on('click', '#hit input', function() {
		$.ajax({
			type: 'POST',
			url: '/game/player/hit'
		}).done(function(msg) {
			$('#game').replaceWith(msg);

		});
		return false;
	});
}

function playerStay() {
	$(document).on('click', '#stay input', function() {
		$.ajax({
			type: 'POST',
			url: '/game/player/stay'
		}).done(function(msg) {
			$('#game').replaceWith(msg);

		});
		return false;
	});
}

function dealerHit() {
	$(document).on('click', '#dealer_hit input', function() {
		$.ajax({
			type: 'POST',
			url: '/game/dealer/hit'
		}).done(function(msg) {
			$('#game').replaceWith(msg);
		});
		return false;
	});
}