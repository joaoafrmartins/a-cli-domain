kosher.alias 'ACliCommand', require 'a-cli-command'

class A extends kosher.ACliCommand

  command:

    name: "command"

    version: "0.0.0"

    description: "a mock command"

    options:

      param:

        alias: "p"

        usage: ""

        description: [
          "a param option",
          "p options are ok",
          "sometimes"
        ]

      action:

        alias: "a"

        usage: ""

        description: [
          "an action option",
          "a options are ok too"
        ]

  "execute?": (command, next) =>

    @cli.executedCommand = true

    next null, @debug "execute"

module.exports =

  "A": A
