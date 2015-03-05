async = require 'async'

{ existsSync } = require 'fs'

{ prompt } = require 'inquirer'

{ resolve } = require 'path'

AConsole = require 'a-cli-console'

aConstructFn = require 'a-construct-fn'

AEventDomain = require 'a-event-domain'

ACliParser = require 'a-cli-parser'

ACliRegistry = require 'a-cli-registry'

ACliRC = require 'a-cli-rc'

class ACliDomain extends AEventDomain

  constructor: (@options={}) ->

    super @options

  extended: () ->

    _options = () =>

      @options ?= {}

      command = name: "cli"

      if _command = @command

        delete @command

        if typeof _command isnt "object"

          command = name: _command

      @options.commandMain ?= command.main

      @options.eventNamespace ?= command.name or "cli"

      @options.commandName ?= command.name or "cli"

      @options.commandVersion ?= command.version

      @options.commandDescription ?= command.description

      @options.commandSynopsys ?= command.synopsys

      @options.commandUsage ?= command.usage

      @options.commandOptions ?= {}

      @options.commandDomainMap ?= {}

      for name, option of command.options

        @options.commandOptions[name] ?= option


      @namespace = ""

      if namespace = @options.eventNamespace

        @namespace = ".#{namespace}"

      @commands = @options.commandDomainMap

    _options()

    _properties = () =>

      if not @package

        Object.defineProperty @, 'package',

          value: ACliRegistry.package require.main.paths[0]

      if not @home

        Object.defineProperty @, 'home',

          value: ACliRegistry.home require.main.paths[0]

      Object.defineProperty @, 'usage',

        value: ACliRegistry.usage

      Object.defineProperty @, 'prompt',

        value: prompt

    _properties()

    # private

    shell = null

    debug = []

    debugStack = []

    debug.push debugStack

    parser = new ACliParser parserDefaultCommand: @options.commandName

    _methods = () =>

      _use = () =>

        @use ?= (command, args...) =>

          try

            if typeof command is "object"

              throw new Error "command should be a module or a function"

            if typeof command is "string"

              main = require.resolve command

              command = require command

              command::command ?= {}

              if typeof command::command is "string"

                command::command = name: command::command

              command::command.main = main

            if typeof command is "function"

              if args.length is 0 then args.push {}

              options = args[args.length-1]

              if not options.eventNamespace

                if command::command

                  eventNamespace = command::command?.name

                eventNamespace ?= @options.eventNamespace

                if @namespace then eventNamespace += @namespace

              options.eventNamespace ?= eventNamespace

              command = new aConstructFn command, args

            if typeof command is "object"

              _shell = () =>

                Object.defineProperty command, 'shell',

                  get: () ->

                    return shell = require 'shelljs/global'

              _shell()

              _exec = () =>

                command.exec ?= (options, next) ->

                  @shell

                  if typeof options is "string"

                    options = bin: options

                  res = exec(options.bin, silent: true)

                  if res.code isnt 0 then return next res.output, null

                  if not options?.silent then @cli.console.info res.output

                  if next then next null, res.output

              _exec()

              _debug = () =>

                command.debug ?= (str) ->

                  if str is null and debugStack.length > 0

                    debug.push debugStack

                    out = debugStack

                    debugStack = []

                    return out

                  debugStack.push str

                  return str

              _debug()

              @commands[command.options.eventNamespace] ?= []

              @commands[command.options.eventNamespace].push command

              @add command

          catch err then @emit "error", err

      _use()

      @run ?= (args=process.argv, callback) =>

        @enabled = true

        parser.once "after.cli-parser", (command) =>

          @trigger command, callback

        if callback then args = [null, null].concat args

        parser.parse args, ACliRegistry.commands

      @trigger ?= (command, callback) =>

        if command.options.length is 0

          return @trigger ACliRegistry.help(command.name)

        _hasEventListener = (event, option) =>

          if option then ns = "#{option.command}#{@namespace}"

          ns ?= "#{command.name}#{@namespace}"

          if commands = @commands[ns]

            for listener in commands

              listener = listener?.options?.eventListeners

              if listener[event] then return true

          return false

        series = []

        command.options.map (option) =>

          event = "#{option.name}.#{option.command}#{@namespace}"

          if _hasEventListener event, option

            series.push (next) =>

              @emit event, command, (err, res) =>

                if err then return next err, null

                @emit "success-#{event}", res

                next null, res

        event = "execute.#{command.name}#{@namespace}"

        if not command.args.help

          if _hasEventListener event

            series.push (next) =>

              @emit event, command, (err, res) =>

                if err then return next err, null

                @emit "success-#{event}", res

                next null, res

        async.series series, (err, res) =>

          if err then throw new Error err

          if callback then callback err, res

      @help ?= () => @trigger ACliRegistry.help()

      @error ?= (err) =>

        @help()

        @console.error err.message, err.stack

      @register ?= (command) =>

        if not command.options.commandName

          command.options.commandName = @options.commandName

          return ACliRegistry.register command, @package

        ACliRegistry.register command

    _mixins = () =>

      AConsole.extend @

      AEventDomain.extend @

    _extended = () =>

      _methods()

      _mixins()

      ACliRegistry.options = @options

      _cache = () =>

        if rc = @package?.cli?.rc

          Object.defineProperty @, "cache", value: new ACliRC

            rcfile: resolve @home, rc

      _cache()

      _init = () =>

        @use 'a-cli-options'

        if commands = @package?.cli?.commands

          if Array.isArray commands

            commands.map (command) =>

              command = resolve @home, 'node_modules', command

              @use command

          else if typeof commands is "object"

            Object.keys(commands).map (command) =>

              if options = commands[command]

                command = resolve @home, 'node_modules', command

                if typeof options is "object"

                  return @use command, options

                @use command


            if not existsSync @cache.rcfile

              @cache.value = @package.cli || _cli =

                rcfile: @cache.rcfile

                commands: commands

              @cache.save()

      _init()

    _extended()

module.exports = ACliDomain
