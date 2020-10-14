const ES_ENDPOINT = "${es_endpoint}"
const AUTHORIZATION = "${authorization}"
const INPUT_DATA_INDEX = "${input_data_index}"
const SCOREBOARD_INDEX = "${scoreboard_index}"
const TRANSFORM_ENABLED = "${transform_enabled}"
const DISPLAY_COUNT = "${display_count}"

function writeEvent(eventData) {

	contentType = "application/json";
	url = ES_ENDPOINT + "/" + INPUT_DATA_INDEX + "/_doc";

	request = new XMLHttpRequest();
	request.open("POST", url, true);
	request.setRequestHeader("Authorization", AUTHORIZATION);
	request.setRequestHeader("Content-Type", contentType);
	request.send(JSON.stringify(eventData));

}

function transformEnabled() {
	return TRANSFORM_ENABLED == "true";
}

function getScoreboardJson(callback) {

	scoreboardValue = [];

	if (transformEnabled()) {
		getScoreboardJsonWithScoreboard(callback);
	} else {
		getScoreboardJsonWithoutScoreboard(callback);
	}

	function getScoreboardJsonWithScoreboard(callback) {

		scoreboardQuery = {
			size: displayCount(),
			sort: [
				{ "game.score.max": "desc" },
				{ "game.level.max": "desc" },
				{ "game.losses.sum": "asc" }
			]	
		};
	
		request = new XMLHttpRequest();
		request.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
				result = JSON.parse(this.responseText);
				hits = result.hits.hits;
				if (hits != null && hits.length > 0) {
					for(i = 0; i < hits.length; i++) {
						entry = {
							user: hits[i]._source.user.keyword,
							score: hits[i]._source.game.score.max,
							level: hits[i]._source.game.level.max,
							losses: hits[i]._source.game.losses.sum,
						};
						scoreboardValue.push(entry);
					}
				}
				callback(scoreboardValue);
			}
		};
		
		url = ES_ENDPOINT + "/" + SCOREBOARD_INDEX + "/_search";
		request.open('POST', url, true);
		request.setRequestHeader("Authorization", AUTHORIZATION);
		request.setRequestHeader('Content-Type', 'application/json');
		request.send(JSON.stringify(scoreboardQuery));
	
	}
	
	function getScoreboardJsonWithoutScoreboard(callback) {
	
		scoreboardQuery = {
			aggs: {
				scoreboard: {
					terms: {
						field: "user.keyword",
						size: displayCount()
					},
					aggs: {
						score: {
							max: {
								field: "game.score"
							}
						},
						level: {
							max: {
								field: "game.level"
							}
						},
						losses: {
							sum: {
								field: "game.losses"
							}
						},
						sorting: {
							bucket_sort: {
								sort: [
									{
										score: {
											order: "desc"
										}
									},
									{
										level: {
											order: "desc"
										}
									},
									{
										losses: {
											order: "asc"
										}
									}
								]
							}
						}
					}
				}
			},
			size: 0
		};
	
		request = new XMLHttpRequest();
		request.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
				result = JSON.parse(this.responseText);
				buckets = result.aggregations.scoreboard.buckets;
				if (buckets != null && buckets.length > 0) {
					for(i = 0; i < buckets.length; i++) {
						entry = {
							user: buckets[i].key,
							score: buckets[i].score.value,
							level: buckets[i].level.value,
							losses: buckets[i].losses.value
						};
						scoreboardValue.push(entry);
					}
				}
				// The scoreboard might have been pre-sorted by Elasticsearch
				// but the REST API call sometimes return the results in a odd
				// order... thus we need to sort the scoreboard again to be sure.
				scoreboardValue = scoreboardValue.sort(function(a, b) {
					res = 0
					if (a.score > b.score) res = 1;
					if (b.score > a.score) res = -1;
					if (a.score == b.score) {
						if (a.level > b.level) res = 1;
						if (b.level > a.level) res = -1;
						if (a.level == b.level) {
							if (a.losses < b.losses) res = 1;
							if (b.losses > a.losses) res = -1;
						} 
					} 
					return res * -1;
				});;			
				callback(scoreboardValue);
			}
		};
		
		url = ES_ENDPOINT + "/" + INPUT_DATA_INDEX + "/_search";
		request.open('POST', url, true);
		request.setRequestHeader("Authorization", AUTHORIZATION);
		request.setRequestHeader('Content-Type', 'application/json');
		request.send(JSON.stringify(scoreboardQuery));
	
	}

}

function displayCount() {
	name = "displayCount".replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
	regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
	results = regex.exec(location.search);
	if (results != null) {
		size = decodeURIComponent(results[1].replace(/\+/g, ' '))
		return parseInt(size);
	} else {
		return parseInt(DISPLAY_COUNT);
	}
}

function loadHighestScore(callback) {

	highestScoreValue = 0;

	if (transformEnabled()) {
		loadHighestScoreWithScoreboard(callback);
	} else {
		loadHighestScoreWithoutScoreboard(callback);
	}

	function loadHighestScoreWithScoreboard(callback) {

		highestScoreQuery = {
			aggs: {
				maxscore: {
					max: {
						field: "game.score.max"
					}
				}
			},
			size: 0
		};
	
		request = new XMLHttpRequest();
		request.onreadystatechange = function() {
			if (this.readyState == 4) {
				if (this.status == 200) {
					result = JSON.parse(this.responseText);
					if (result != undefined || result != null) {
						highestScoreValue = result.aggregations.maxscore.value;
					}
				}
				callback(highestScoreValue);
			}
		};
	
		url = ES_ENDPOINT + "/" + SCOREBOARD_INDEX + "/_search";
		request.open('POST', url, true);
		request.setRequestHeader("Authorization", AUTHORIZATION);
		request.setRequestHeader('Content-Type', 'application/json');
		request.send(JSON.stringify(highestScoreQuery));
	
	}
	
	function loadHighestScoreWithoutScoreboard(callback) {
	
		highestScoreQuery = {
			aggs: {
				maxscore: {
					max: {
						field: "game.score"
					}
				}
			},
			size: 0
		};
	
		request = new XMLHttpRequest();
		request.onreadystatechange = function() {
			if (this.readyState == 4) {
				if (this.status == 200) {
					result = JSON.parse(this.responseText);
					if (result != undefined || result != null) {
						highestScoreValue = result.aggregations.maxscore.value;
					}
				}
				callback(highestScoreValue);
			}
		};
	
		url = ES_ENDPOINT + "/" + INPUT_DATA_INDEX + "/_search";
		request.open('POST', url, true);
		request.setRequestHeader("Authorization", AUTHORIZATION);
		request.setRequestHeader('Content-Type', 'application/json');
		request.send(JSON.stringify(highestScoreQuery));
	
	}

}

function loadLastData(callback) {

	lastData = {
		score: 0,
		level: 1
	};

	if (transformEnabled()) {
		loadLastDataWithScoreboard(callback);
	} else {
		loadLastDataWithoutScoreboard(callback);
	}

	function loadLastDataWithScoreboard(callback) {

		lastDataQuery = {
			query: {
				bool: {
					must: [
						{
							match: {
								"user.keyword": USER
							}
						}
					]
				}
			},
			size: 1
		}
	
		request = new XMLHttpRequest();
		request.onreadystatechange = function() {
			if (this.readyState == 4) {
				if (this.status == 200) {
					result = JSON.parse(this.responseText);
					if (result != undefined || result != null) {
						hits = result.hits.hits;
						if (hits.length > 0) {
							lastData.score = hits[0]._source.game.score.max;
							lastData.level = hits[0]._source.game.level.max;
						}
					}
				}
				callback(lastData);
			}
		};
	
		url = ES_ENDPOINT + "/" + SCOREBOARD_INDEX + "/_search";
		request.open('POST', url, true);
		request.setRequestHeader("Authorization", AUTHORIZATION);
		request.setRequestHeader('Content-Type', 'application/json');
		request.send(JSON.stringify(lastDataQuery));
	
	}
	
	function loadLastDataWithoutScoreboard(callback) {
	
		lastDataQuery = {
			query: {
				bool: {
					must: [
						{
							match: {
								user: USER
							}
						}
					]
				}
			},
			size: 1,
			aggs: {
				lastScore: {
					max: {
						field: "game.score"
					}
				},
				lastLevel: {
					max: {
						field: "game.level"
					}
				}
			}
		};
	
		request = new XMLHttpRequest();
		request.onreadystatechange = function() {
			if (this.readyState == 4) {
				if (this.status == 200) {
					result = JSON.parse(this.responseText);
					if (result != undefined || result != null) {
						lastData.score = result.aggregations.lastScore.value;
						lastData.level = result.aggregations.lastLevel.value;
					}
				}
				callback(lastData);
			}
		};
	
		url = ES_ENDPOINT + "/" + INPUT_DATA_INDEX + "/_search";
		request.open('POST', url, true);
		request.setRequestHeader("Authorization", AUTHORIZATION);
		request.setRequestHeader('Content-Type', 'application/json');
		request.send(JSON.stringify(lastDataQuery));
	
	}

}
