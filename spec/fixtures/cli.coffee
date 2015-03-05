kosher.alias 'ACliDomain'

class ACli extends kosher.ACliDomain

class A extends ACli

  command: main: __dirname

class B extends ACli

  command: main: __dirname

  run: () -> @ran = true

module.exports =

  "A": A

  "B": B
