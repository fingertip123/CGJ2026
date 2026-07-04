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
    ShowWelcome()

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
    _StopBgm()
    _StopResultMusic()
    _PlayWelcome()

func ShowWin() -> void:
    pWelcomeScreen.visible = false
    pWinScreen.visible = true
    pLoseScreen.visible = false
    _StopWelcome()
    _StopBgm()
    _PlayResult(pWinPlayer)

func ShowLose() -> void:
    pWelcomeScreen.visible = false
    pWinScreen.visible = false
    pLoseScreen.visible = true
    _StopWelcome()
    _StopBgm()
    _PlayResult(pLosePlayer)

func StartGameFromWelcome() -> void:
    pWelcomeScreen.visible = false
    _StopWelcome()
    _PlayBgm()
    emit_signal("WelcomeFinished")

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
    pBgmPlayer.stop()
    pBgmPlayer.play()

func _StopBgm() -> void:
    pBgmPlayer.stop()

func _PlayResult(pPlayer: AudioStreamPlayer) -> void:
    if pPlayer.stream == null:
        return
    pPlayer.stop()
    pPlayer.play()

func _StopResultMusic() -> void:
    pWinPlayer.stop()
    pLosePlayer.stop()
