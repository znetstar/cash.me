require 'shelljs/make'
coffee = require 'coffee-script'

target.clean = () ->
	rm '-rf', './lib'

target.lib = ->
	!(test '-e', './lib') and (mkdir pwd()+'/lib')
	ls(pwd()+'/src').filter((p) -> p.indexOf('.coffee') isnt -1).forEach (path) ->
		path = pwd()+'/src/'+path
		script = cat(path)
		coffee.compile(script).to(path.replace('/src/', '/lib/').replace('.coffee', '.js'))

target.all = ->
	target.lib()