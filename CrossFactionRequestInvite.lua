local function getGameAccountIDByTravelPassButton(travelPassButton)
    local gameAccountID;
    local friendIndex = travelPassButton:GetParent().id;
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

    return gameAccountID;
end
local function onClick(travelPassButton)
    local gameAccountID = getGameAccountIDByTravelPassButton(travelPassButton);

    if gameAccountID then BNRequestInviteFriend(gameAccountID); end
end
local function onEnter(travelPassButton)
    ExecuteFrameScript(travelPassButton, 'OnEnter');
    local gameAccountID = getGameAccountIDByTravelPassButton(travelPassButton);

    if gameAccountID then
        GameTooltip:AddLine('Right-Click to force a request invite', 0, 1, 0);
        GameTooltip:Show();
    end
end

local eventFrame = CreateFrame("Frame");
eventFrame.combatLockdownQueue = {};
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...);
    end
end);

--- @param func function
--- @param ... any # arguments
local function addToCombatLockdownQueue(func, ...)
    if #eventFrame.combatLockdownQueue == 0 then
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
    end

    tinsert(eventFrame.combatLockdownQueue, { func = func, args = { ... } });
end

function eventFrame:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED");
    if #self.combatLockdownQueue == 0 then return; end

    for _, item in pairs(self.combatLockdownQueue) do
        item.func(unpack(item.args));
    end
    wipe(self.combatLockdownQueue);
end

local function passThroughLeftClick(btn)
    -- pass through the leftclick for default behaviour
    -- note: in 11.0, we can use SetPropagateMouseMotion, and hook the travelPassButton's OnEnter
    btn:SetPassThroughButtons('LeftButton');
end

local function handleFriendListButtons()
    if
        FriendsListFrame
        and FriendsListFrame.ScrollBox
        and FriendsListFrame.ScrollBox.ScrollTarget
        and FriendsListFrame.ScrollBox.ScrollTarget.GetChildren
    then
        local buttons = {FriendsListFrame.ScrollBox.ScrollTarget:GetChildren()};
        for _, button in pairs(buttons) do
            if not button.travelPassButton or button.CrossFactionRequestInviteButton then
                return;
            end
            button.CrossFactionRequestInviteButton = CreateFrame('BUTTON', nil, button.travelPassButton);
            button.CrossFactionRequestInviteButton:SetAllPoints();
            button.CrossFactionRequestInviteButton:RegisterForClicks('RightButtonDown');
            button.CrossFactionRequestInviteButton:SetScript('OnEnter', function() onEnter(button.travelPassButton); end);
            button.CrossFactionRequestInviteButton:SetScript('OnLeave', function() GameTooltip:Hide(); end);
            button.CrossFactionRequestInviteButton:SetScript('OnClick', function() onClick(button.travelPassButton); end);
            if not InCombatLockdown() then
                passThroughLeftClick(button.CrossFactionRequestInviteButton);
            else
                addToCombatLockdownQueue(passThroughLeftClick, button.CrossFactionRequestInviteButton);
            end
        end
    end
end

do
    if FriendsList_Update then
        hooksecurefunc('FriendsList_Update', handleFriendListButtons);
    end
    handleFriendListButtons();
end
