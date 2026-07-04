extends Control

const UnitData = preload("res://scripts/unit_data.gd")

signal CardPressed(nIndex)
signal RefreshPressed()
signal UpgradePressed()

onready var pCardHBox = $CardHBox
onready var pRefreshButton = $RefreshButton
onready var pUpgradeButton = $UpgradeButton
onready var pGoldLabel = $GoldLabel
onready var pPoolLabel = $PoolLabel

var vCardButtons = []

func _ready() -> void:
    pRefreshButton.connect("pressed", self, "_OnRefreshPressed")
    pUpgradeButton.connect("pressed", self, "_OnUpgradePressed")
    for pChild in pCardHBox.get_children():
        if pChild is Button:
            vCardButtons.append(pChild)
            var nIndex = vCardButtons.size() - 1
            pChild.connect("pressed", self, "_OnCardPressed", [nIndex])

func UpdateDisplay(nGold: int, vCards: Array, nVisibleSlots: int, nRefreshCooldown: float, nRefreshCost: int, bCanRefresh: bool, nShipLevel: int, nUpgradeCost: int, bCanUpgrade: bool, nDroneCount: int, nDroneMax: int) -> void:
    pGoldLabel.text = "Gold: %d" % nGold
    pPoolLabel.text = "Ship Lv.%d  Drones: %d/%d  Cards: %d" % [nShipLevel, nDroneCount, nDroneMax, nVisibleSlots]

    for i in range(vCardButtons.size()):
        var pBtn = vCardButtons[i]
        if i >= nVisibleSlots:
            pBtn.visible = false
            continue
        pBtn.visible = true
        if i < vCards.size():
            var oCard = vCards[i]
            var sName = UnitData.GetDroneName(oCard.type)
            pBtn.text = "[Drone]\n%s\n%d G" % [sName, oCard.cost]
            var bCanBuy = nGold >= oCard.cost and nDroneCount < nDroneMax
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
