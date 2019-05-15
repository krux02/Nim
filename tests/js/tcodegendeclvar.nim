discard """
  output: '''
-1
2
'''
  jscodecheck: "'console.log(-1); var v_' \\d+ ' = [2]'"
"""

var v {.codegenDecl: "console.log(-1); var $2".} = 2
echo v
