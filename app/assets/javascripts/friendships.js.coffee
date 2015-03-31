# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(".friendships.index").ready ->
  $("#email_search").autocomplete
    serviceUrl: '/friends/search.json',
    minChars: 3,
    paramName: 'email'
