extends CanvasLayer

signal WelcomeFinished
signal ResetRequested

const WelcomeTexture = preload("res://images/welcomeBg.png")
const WinTexture = preload("res://images/win.png")
const LoseTexture = preload("res://images/lose.png")
const WelcomeMusic = preload("res://music/welcome.mp3")
const BgmMusic = preload("res://music/bgm.mp3")
const WinMusic = preload("res://music/win.mp3")
const LoseMusic = preload("res://music/lose.mp3")
const DangerMusic = preload("res://music/danger.mp3")

const nMusicFadeSpeed = 0.85
const nSilentDb = -80.0

onready var pWelcomeScreen = $WelcomeScreen
onready var pWinScreen = $WinScreen
onready var pLoseScreen = $LoseScreen
onready var pWelcomeBg = $WelcomeScreen/WelcomeBg
onready var pWinBg = $WinScreen/WinBg
onready var pLoseBg = $LoseScreen/LoseBg
onready var pStartButton = $WelcomeScreen/StartButton
onready var pWinResetButton = $WinScreen/ResetButton
onready var pLoseResetButton = $LoseScreen/ResetButton
onready var pWelcomePlayer = $MusicRoot/WelcomePlayer
onready var pBgmPlayer = $MusicRoot/BgmPlayer
onready var pWinPlayer = $MusicRoot/WinPlayer
onready var pLosePlayer = $MusicRoot/LosePlayer
onready var pDangerPlayer = $MusicRoot/DangerPlayer

var bGameplayMusicActive = false
var bDangerActive = false
var nBgmFade = 1.0
var nDangerFade = 0.0

func _ready() -> void:
    layer = 100
    pStartButton.connect("pressed", self, "_OnStartPressed")
    pWinResetButton.connect("pressed", self, "_OnResetPressed")
    pLoseResetButton.connect("pressed", self, "_OnResetPressed")
    _SetupTexture(pWelcomeBg, WelcomeTexture)
    _SetupTexture(pWinBg, WinTexture)
    _SetupTexture(pLoseBg, LoseTexture)
    _SetupMusicPlayer(pWelcomePlayer, WelcomeMusic, true)
    _SetupMusicPlayer(pBgmPlayer, BgmMusic, true)
    _SetupMusicPlayer(pWinPlayer, WinMusic, false)
    _SetupMusicPlayer(pLosePlayer, LoseMusic, false)
    _SetupMusicPlayer(pDangerPlayer, DangerMusic, true)
    set_process(true)
    ShowWelcome()

func _process(delta: float) -> void:
    if not bGameplayMusicActive:
        return

    var nTargetBgm = 0.0 if bDangerActive else 1.0
    var nTargetDanger = 1.0 if bDangerActive else 0.0
    nBgmFade = move_toward(nBgmFade, nTargetBgm, nMusicFadeSpeed * delta)
    nDangerFade = move_toward(nDangerFade, nTargetDanger, nMusicFadeSpeed * delta)
    _ApplyMusicVolumes()

func _SetupTexture(pRect: TextureRect, pTexture) -> void:
    if pRect == null or pTexture == null:
        return
    pRect.texture = pTexture
    pRect.expand = true
    pRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

func _SetupMusicPlayer(pPlayer: AudioStreamPlayer, pStream, bLoop: bool) -> void:
    if pPlayer == null or pStream == null:
        return
    var pCopy = pStream.duplicate()
    pCopy.loop = bLoop
    pPlayer.stream = pCopy

func ShowWelcome() -> void:
    pWelcomeScreen.visible = true
    pWinScreen.visible = false
    pLoseScreen.visible = false
    _ResetDangerMusic()
    _StopBgm()
    _StopResultMusic()
    _PlayWelcome()

func ShowWin() -> void:
    pWelcomeScreen.visible = false
    pWinScreen.visible = true
    pLoseScreen.visible = false
    _StopWelcome()
    _ResetDangerMusic()
    _StopBgm()
    _PlayResult(pWinPlayer)

func ShowLose() -> void:
    pWelcomeScreen.visible = false
    pWinScreen.visible = false
    pLoseScreen.visible = true
    _StopWelcome()
    _ResetDangerMusic()
    _StopBgm()
    _PlayResult(pLosePlayer)

func StartGameFromWelcome() -> void:
    pWelcomeScreen.visible = false
    _StopWelcome()
    bGameplayMusicActive = true
    bDangerActive = false
    nBgmFade = 1.0
    nDangerFade = 0.0
    _ApplyMusicVolumes()
    _PlayBgm()
    emit_signal("WelcomeFinished")

func UpdateDangerMusic(bActive: bool) -> void:
    if not bGameplayMusicActive:
        return
    bDangerActive = bActive

func _OnStartPressed() -> void:
    StartGameFromWelcome()

func _OnResetPressed() -> void:
    emit_signal("ResetRequested")

func _PlayWelcome() -> void:
    if pWelcomePlayer.stream == null:
        return
    pWelcomePlayer.stop()
    pWelcomePlayer.play()

func _StopWelcome() -> void:
    pWelcomePlayer.stop()

func _PlayBgm() -> void:
    if pBgmPlayer.stream == null:
        return
    pBgmPlayer.volume_db = _LinearToDb(nBgmFade)
    pBgmPlayer.stop()
    pBgmPlayer.play()

func _StopBgm() -> void:
    pBgmPlayer.stop()
    pBgmPlayer.volume_db = nSilentDb

func _EnsureDangerPlaying() -> void:
    if pDangerPlayer.stream == null:
        return
    if not pDangerPlayer.playing:
        pDangerPlayer.play()

func _StopDanger() -> void:
    pDangerPlayer.stop()
    pDangerPlayer.volume_db = nSilentDb

func _ResetDangerMusic() -> void:
    bGameplayMusicActive = false
    bDangerActive = false
    nBgmFade = 1.0
    nDangerFade = 0.0
    _StopDanger()

func _ApplyMusicVolumes() -> void:
    pBgmPlayer.volume_db = _LinearToDb(nBgmFade)
    pDangerPlayer.volume_db = _LinearToDb(nDangerFade)
    if nDangerFade > 0.001:
        _EnsureDangerPlaying()
    elif pDangerPlayer.playing:
        _StopDanger()

func _LinearToDb(nLinear: float) -> float:
    return lerp(nSilentDb, 0.0, clamp(nLinear, 0.0, 1.0))

func _PlayResult(pPlayer: AudioStreamPlayer) -> void:
    if pPlayer.stream == null:
        return
    pPlayer.stop()
    pPlayer.play()

func _StopResultMusic() -> void:
    pWinPlayer.stop()
    pLosePlayer.stop()
