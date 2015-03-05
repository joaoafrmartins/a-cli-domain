describe 'ACliDomain', () ->

  it 'before', () ->

    kosher.alias 'fixture', kosher.spec.fixtures

    kosher.alias 'instance', new kosher.fixture.cli.B

  describe 'properties', () ->

  describe 'methods', () ->

    describe 'use', () ->

      it 'should register event emitter as new command', () ->

        command = kosher.fixture.command.A
        kosher.instance.options.eventDomainMembers.should.be.Array
        kosher.instance.options.eventDomainMembers.length.should.
        not.be.above 1

        kosher.instance.use command
        kosher.instance.options.eventDomainMembers.should.be.Array
        kosher.instance.options.eventDomainMembers.length.should.
        not.be.below 1

        kosher.instance.enable = true

      it 'should read command info from package.json files', () ->

        kosher.alias 'instance', new kosher.fixture.cli.A

        kosher.instance.package.should.be.ok

      it 'should autoload "cli" package.json field'


    describe 'run', () ->

      it 'should be able to pass parsed args to execute event', () ->

        kosher.argv "command", "-a", "action", "--param", "param"

        kosher.alias 'instance', new kosher.fixture.cli.A

        kosher.instance.use kosher.fixture.command.A

        kosher.instance.run()

        kosher.instance.executedCommand.should.be.true

      it 'should show usage information when arguments are invalid', (done) ->

        kosher.alias 'stream', new kosher.WriteableStream

        kosher.argv "--no", "op"

        kosher.alias 'instance', new kosher.fixture.cli.A

          consoleOutputStream: kosher.stream

          consoleErrorStream: kosher.stream

        kosher.stream.on "data", (data) ->

          done()

        kosher.instance.run()
