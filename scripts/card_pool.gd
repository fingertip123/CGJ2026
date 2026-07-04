extends Control

const UnitData = preload("res://scripts/unit_data.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")

signal CardPressed(nIndex)
signal RefreshPressed()
signal UpgradePressed()

onready var pBackground = $Background
onready var pCardHBox = $CardHBox
onready var pRefreshButton = $RefreshButton
onready var pUpgradeButton = $UpgradeButton
onready var pGoldLabel = $GoldLabel
onready var pPoolLabel = $PoolLabel

var vCardButtons = []

func _ready() -> void:
    UiTheme.ApplyToControl(self)
    pBackground.color = UiTheme.C_BG
    UiTheme.StyleLabel(pGoldLabel, UiTheme.C_ACCENT)
    UiTheme.StyleLabel(pPoolLabel, UiTheme.C_TEXT_MUTED)
    pRefreshButton.connect("pressed", self, "_OnRefreshPressed")
    pUpgradeButton.connect("pressed", self, "_OnUpgradePressed")
    for pChild in pCardHBox.get_children():
        if pChild is Button:
            vCardButtons.append(pChild)
            var nIndex = vCardButtons.size() - 1
            pChild.connect("pressed", self, "_OnCardPressed", [nIndex])

func UpdateDisplay(nGold: int, vCards: Array, nVisibleSlots: int, nRefreshCooldown: float, nRefreshCost: int, bCanRefresh: bool, nShipLevel: int, nUpgradeCost: int, bCanUpgrade: bool, nDroneCount: int, nDroneMax: int, nMiningCount: int, nMiningMax: int) -> void:
    pGoldLabel.text = "GOLD %d" % nGold
    pPoolLabel.text = "LV.%d  ESCORT %d/%d  MINING %d/%d  SLOTS %d" % [
        nShipLevel, nDroneCount, nDroneMax, nMiningCount, nMiningMax, nVisibleSlots
    ]

    for i in range(vCardButtons.size()):
        var pBtn = vCardButtons[i]
        if i >= nVisibleSlots:
            pBtn.visible = false
            continue
        pBtn.visible = true
        if i < vCards.size():
            var oCard = vCards[i]
            var sName = UnitData.GetCardName(oCard)
            var sTag = "[Mine]" if oCard.get("kind", UnitData.CardKind.ESCORT) == UnitData.CardKind.MINING else "[Escort]"
            pBtn.text = "%s\n%s\n%d G" % [sTag, sName, oCard.cost]
            var bCanBuy = false
            if oCard.get("kind", UnitData.CardKind.ESCORT) == UnitData.CardKind.MINING:
                bCanBuy = nGold >= oCard.cost and nMiningCount < nMiningMax
            else:
                bCanBuy = nGold >= oCard.cost and nDroneCount < nDroneMax
            pBtn.disabled = not bCanBuy
        else:
            pBtn.text = "-"
            pBtn.disabled = true

    if nRefreshCooldown > 0.0:
        pRefreshButton.text = "Refresh (%.1fs)" % nRefreshCooldown
        pRefreshButton.disabled = true
    else:
        pRefreshButton.text = "Refresh All (%d G)" % nRefreshCost
        pRefreshButton.disabled = not bCanRefresh

    if bCanUpgrade:
        pUpgradeButton.text = "Upgrade Ship (%d G)" % nUpgradeCost
        pUpgradeButton.disabled = nGold < nUpgradeCost
    else:
        pUpgradeButton.text = "Ship MAX"
        pUpgradeButton.disabled = true

func _OnCardPressed(nIndex: int) -> void:
    emit_signal("CardPressed", nIndex)

func _OnRefreshPressed() -> void:
    emit_signal("RefreshPressed")

func _OnUpgradePressed() -> void:
    emit_signal("UpgradePressed")
