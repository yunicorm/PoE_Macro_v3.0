; ==============================================================================
; オーバーレイ更新処理モジュール
; ==============================================================================

; --- オーバーレイ更新処理 ---
UpdateOverlay() {
    global isRunning
    
    if (!isRunning) {
        return
    }
    
    currentTime := A_TickCount
    
    ; ②アドレナリン更新
    UpdateAdrenalineOverlay(currentTime)
    
    ; ③Tincture更新
    UpdateTinctureOverlay(currentTime)
    
    ; ④Gold Flask更新
    UpdateGoldFlaskOverlay(currentTime)
    
    ; ⑤スキルB更新
    UpdateRegularSkillOverlay("B", currentTime)
    
    ; ⑥～⑨スキルキュー更新
    UpdateSkillQueueOverlay("L", currentTime)
    UpdateSkillQueueOverlay("K", currentTime)
    UpdateSkillQueueOverlay("O", currentTime)
    UpdateSkillQueueOverlay("N", currentTime)
    
    ; ⑩スキルT更新
    UpdateRegularSkillOverlay("T", currentTime)
}

; --- アドレナリン更新 ---
UpdateAdrenalineOverlay(currentTime) {
    global lastAdrenalineTime, interval_adrenaline_min
    
    if (lastAdrenalineTime = 0) {
        GuiControl, Adrenaline:, Adrenaline_Text, Ready
        GuiControl, Adrenaline:, Adrenaline_Progress, 100
        return
    }
    
    elapsed := currentTime - lastAdrenalineTime
    remaining := interval_adrenaline_min - elapsed
    
    if (remaining <= 0) {
        GuiControl, Adrenaline:, Adrenaline_Text, Ready
        GuiControl, Adrenaline:, Adrenaline_Progress, 100
    } else {
        seconds := Round(remaining / 1000, 1)
        GuiControl, Adrenaline:, Adrenaline_Text, %seconds%s
        progress := 100 * (remaining / interval_adrenaline_min)
        GuiControl, Adrenaline:, Adrenaline_Progress, %progress%
    }
}

; --- Tincture更新 ---
UpdateTinctureOverlay(currentTime) {
    global tinctureActive, tinctureLastUsedTime, duration_tincture
    global cooldown_tincture_min, manaBurnStackRate
    global manaBurnStacks, manaBurnLastUpdate
    
    ; 変数の初期化チェック
    if (tinctureActive = "") {
        tinctureActive := false
    }
    if (tinctureLastUsedTime = "") {
        tinctureLastUsedTime := 0
    }
    
    if (tinctureActive) {
        ; Mana Burnスタック計算
        if (manaBurnLastUpdate = 0) {
            manaBurnLastUpdate := currentTime
            manaBurnStacks := 0
        }
        
        stackElapsed := currentTime - manaBurnLastUpdate
        if (stackElapsed >= manaBurnStackRate) {
            manaBurnStacks += Floor(stackElapsed / manaBurnStackRate)
            manaBurnLastUpdate := currentTime
        }
        
        GuiControl, Tincture:, Tincture_Text, Active: %manaBurnStacks%
        
        ; プログレスバー（アクティブ時は100%）
        GuiControl, Tincture:, Tincture_Progress, 100
        GuiControl, Tincture:+c00FF00, Tincture_Progress
    } else {
        manaBurnStacks := 0
        manaBurnLastUpdate := 0
        
        if (tinctureLastUsedTime > 0) {
            ; クールダウン中
            elapsed := currentTime - (tinctureLastUsedTime + duration_tincture)
            remaining := cooldown_tincture_min - elapsed
            
            if (remaining > 0) {
                GuiControl, Tincture:, Tincture_Text, Deactive
                progress := 100 * (1 - (elapsed / cooldown_tincture_min))
                GuiControl, Tincture:, Tincture_Progress, %progress%
                GuiControl, Tincture:+cFFFFCC, Tincture_Progress
            } else {
                GuiControl, Tincture:, Tincture_Text, Ready
                GuiControl, Tincture:, Tincture_Progress, 100
                GuiControl, Tincture:+c00FF00, Tincture_Progress
            }
        } else {
            GuiControl, Tincture:, Tincture_Text, Ready
            GuiControl, Tincture:, Tincture_Progress, 100
            GuiControl, Tincture:+c00FF00, Tincture_Progress
        }
    }
}

; --- Gold Flask更新 ---
UpdateGoldFlaskOverlay(currentTime) {
    global lastGoldFlaskTime, interval_goldFlask_min
    
    if (lastGoldFlaskTime = 0) {
        GuiControl, GoldFlask:, GoldFlask_Text, Ready
        GuiControl, GoldFlask:, GoldFlask_Progress, 100
        return
    }
    
    elapsed := currentTime - lastGoldFlaskTime
    remaining := interval_goldFlask_min - elapsed
    
    if (remaining <= 0) {
        GuiControl, GoldFlask:, GoldFlask_Text, Ready
        GuiControl, GoldFlask:, GoldFlask_Progress, 100
    } else {
        seconds := Round(remaining / 1000, 1)
        GuiControl, GoldFlask:, GoldFlask_Text, %seconds%s
        progress := 100 * (remaining / interval_goldFlask_min)
        GuiControl, GoldFlask:, GoldFlask_Progress, %progress%
    }
}

; --- 定期実行スキル更新 ---
UpdateRegularSkillOverlay(key, currentTime) {
    global lastSkillTTime, lastSkillBTime
    global interval_skill_T_min, interval_skill_B_min
    
    if (key = "T") {
        lastTime := lastSkillTTime
        interval := interval_skill_T_min
        guiName := "SkillT"
    } else if (key = "B") {
        lastTime := lastSkillBTime
        interval := interval_skill_B_min
        guiName := "SkillB"
    }
    
    if (lastTime = 0) {
        GuiControl, %guiName%:, %guiName%_Text, Ready
        GuiControl, %guiName%:, %guiName%_Progress, 100
        return
    }
    
    elapsed := currentTime - lastTime
    remaining := interval - elapsed
    
    if (remaining <= 0) {
        GuiControl, %guiName%:, %guiName%_Text, Ready
        GuiControl, %guiName%:, %guiName%_Progress, 100
    } else {
        seconds := Round(remaining / 1000, 1)
        GuiControl, %guiName%:, %guiName%_Text, %seconds%s
        progress := 100 * (remaining / interval)
        GuiControl, %guiName%:, %guiName%_Progress, %progress%
    }
}

; --- スキルキュー更新 ---
UpdateSkillQueueOverlay(key, currentTime) {
    global skillNextTime, skillCooldowns
    global currentExertCounts, warcryExertCounts, enableExertCounter
    
    guiName := "Skill" . key
    
    ; オブジェクトの存在チェック
    if (!IsObject(skillNextTime) || !IsObject(skillCooldowns)) {
        return
    }
    
    nextTime := skillNextTime[key]
    cooldown := skillCooldowns[key]
    
    ; 基本のクールダウン表示更新
    if (nextTime <= currentTime) {
        if (key = "O") {
            GuiControl, %guiName%:, %guiName%_Text, Guard
        } else {
            GuiControl, %guiName%:, %guiName%_Text, Ready
        }
        GuiControl, %guiName%:, %guiName%_Progress, 100
    } else {
        remaining := nextTime - currentTime
        seconds := Round(remaining / 1000, 1)
        GuiControl, %guiName%:, %guiName%_Text, %seconds%s
        progress := 100 * (remaining / cooldown)
        GuiControl, %guiName%:, %guiName%_Progress, %progress%
    }
    
    ; Exertカウント表示の更新
    if (IsObject(warcryExertCounts) && IsObject(currentExertCounts) && enableExertCounter && warcryExertCounts[key] > 0) {
        count := currentExertCounts[key]
        maxCount := warcryExertCounts[key]
        
        ; カウントに応じて色を変更
        if (count = 0) {
            GuiControl, %guiName%:+cFF4444, %guiName%_Exert  ; 赤
        } else if (count <= maxCount / 3) {
            GuiControl, %guiName%:+cFFAA00, %guiName%_Exert  ; オレンジ（残り1/3以下）
        } else if (count = maxCount) {
            GuiControl, %guiName%:+c00FF00, %guiName%_Exert  ; 緑（フル）
        } else {
            GuiControl, %guiName%:+cFFFF00, %guiName%_Exert  ; 黄（通常）
        }
        
        GuiControl, %guiName%:, %guiName%_Exert, %count%
    }
}