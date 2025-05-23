# UserData.gd
extends Node

var current_auth = null
var username = ""
var level = 1
var player_xp = 0
var level_rewards = {}  #Laver en dictionary hvor vi kan gemme de rewards de allerede har fået
var pending_level_ups: Array = []
