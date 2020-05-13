discard """
  output: ""
"""

# bug #2880

type
  TMsgKind* = enum
    err0, err1, err2, err3, err4,
    err5, err6,
    err7, err8,
    err9, err10,
    err11, err12, err13,
    err14, err15, err16,
    err17, err18, err19,
    err20, err21, err22,
    err23, err24, err25,
    err26, err27, err28,
    err29, err30, err31,
    err32, err33, err34,
    err35, err36,
    err37, err38,
    err39, err40, err41,
    err42, err43, err44,
    err45, err46, err47,
    err48, err49, err50,
    err51, err52,
    err53,
    err54, err55,
    err56, err57, err58,
    err59, err60, err61,
    err62, err63, err64, err65,
    err66, err67, err68,
    err69, err70, err71,
    err72, err73, err74,
    err75, err76,
    err77, err78,
    err79, err80_255,
    err81, err82, err83,
    err84, err85, err86,
    err87, err88, err89,
    err90, err91, err92,
    err93, err94, err95,
    err96, err97, err98,
    err99, err100,
    err101, err102, err103,
    err104, err105, err106,
    err107, err108, err109,
    err110, err111, err112,
    err113, err114, err115,
    err116, err117, err118,
    err119, err120, err121,
    err122, err123,
    err124, err125,
    err126, err127, err128,
    err129,
    err130, err131, err132, err133,
    err134, err135,
    err136,
    err137, err138, err139,
    err140, err141, err142,
    err143, err144, err145,
    err146,
    err147, err148, err149, err150,
    err151, err152, err153,
    err154, err155, err156,
    err157, err158,
    err159, err160, err161,
    err162, err163, err164,
    err165, err166,
    err167, err168, err169,
    err170, err171, err172,
    err173, err174,
    err175, err176, err177,
    err178, err179, err180,
    err181,
    err182, err183,
    err184,
    err185, err186,
    err187, err188,
    err189,
    err190,
    err191,
    err192, err193, err194,
    err195, err196, err197,
    err198, err199, err200,
    err201, err202,
    err203,
    err204,
    err205,
    err206,
    err207, err208, err209,
    err210, err211, err212,
    err213, err214, err215,
    err216, err217, err218,
    err219, err220, err221,
    err222, err223, err224,
    err225, err226,
    err227,
    err228,
    err229,
    err230,
    err231,

    warn0,
    warn1, warn2, warn3,
    warn4, warn5,
    warn6, warn7, warn8,
    warn9, warn10,
    warn11, warn12,
    warn13, warn14,
    warn15, warn16, warn17,
    warn18
    warn19, warn20, warn21, warn22, warn23,
    warn24, warn25, warn26, warn27, warn28,
    warn29,
    hint0, hint1,
    hint2, hint3, hint4,
    hint5, hint6, hint7,
    hint8, hint9, hint10, hint11, hint12,
    hint13, hint14, hint15,
    hint16, hint17, hint18,
    hint19, hint20, hint21,
    hint22

const
  warnMin = warn0
  hintMax = high(TMsgKind)

type
  TNoteKind = range[warnMin..hintMax] # "notes" are warnings or hints
  TNoteKinds = set[TNoteKind]

const
  NotesVerbosityConst: array[0..0, TNoteKinds] = [
    {low(TNoteKind)..high(TNoteKind)} - {hint14}]
  fuckyou = NotesVerbosityConst[0]

var
  gNotesFromConst: TNoteKinds = NotesVerbosityConst[0]
  gNotesFromConst2: TNoteKinds = fuckyou

if hint14 in gNotesFromConst:
  echo "hintGCStats in gNotesFromConst A"

if hint14 in gNotesFromConst2:
  echo "hintGCStats in gNotesFromConst B"
