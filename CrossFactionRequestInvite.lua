local handledButtons = {}
local function getGameAccountIDByTravelPassButton(travelPassButton)
    local gameAccountID
    local friendIndex = travelPassButton:GetParent().id
    local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(friendIndex);
    if numGameAccounts > 1 then
        for i = 1, numGameAccounts do
            local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(friendIndex, i);
            if gameAccountInfo.playerGuid and (gameAccountInfo.realmID ~= 0) then
                gameAccountID = gameAccountInfo.gameAccountID;
                break;
            end
        end
    else
        local accountInfo = C_BattleNet.GetFriendAccountInfo(friendIndex);
        if accountInfo and accountInfo.gameAccountInfo.playerGuid then
            gameAccountID = accountInfo.gameAccountInfo.gameAccountID;
        end
    end

    return gameAccountID
end
local function onClick(travelPassButton, btn)
    if btn == "LeftButton" then
        return
    end
    -- undo the default behavior
    FriendsFrame_BattlenetInviteByIndex(travelPassButton:GetParent().id)

    local gameAccountID = getGameAccountIDByTravelPassButton(travelPassButton)

    if gameAccountID then BNRequestInviteFriend(gameAccountID) end
end
local function onEnter(travelPassButton)
    local gameAccountID = getGameAccountIDByTravelPassButton(travelPassButton)

    if gameAccountID then
        GameTooltip:AddLine("Right-Click to force a request invite", 0, 1, 0)
        GameTooltip:Show()
    end
end

local function handleFriendListButtons()
    if
        FriendsListFrame
        and FriendsListFrame.ScrollBox
        and FriendsListFrame.ScrollBox.ScrollTarget
        and FriendsListFrame.ScrollBox.ScrollTarget.GetChildren
    then
        local buttons = {FriendsListFrame.ScrollBox.ScrollTarget:GetChildren()}
        for _, button in pairs(buttons) do
            if not button.travelPassButton or handledButtons[button] then
                return
            end
            handledButtons[button] = true
            button.travelPassButton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
            -- register leftclick for default behavior
            button.travelPassButton:HookScript("OnEnter", onEnter)
            button.travelPassButton:HookScript("OnClick", onClick)
        end
    end
end

do
    if FriendsList_Update then
        hooksecurefunc("FriendsList_Update", handleFriendListButtons)
    end
    handleFriendListButtons()
end
