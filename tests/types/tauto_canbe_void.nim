discard """
output: '''
arg
arg
'''
"""


import sugar

template tempo(s: untyped) =
  s("arg")

tempo((s: string)->auto => echo(s))
tempo((s: string) => echo(s))
