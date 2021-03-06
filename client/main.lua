ESX = nil

TriggerEvent(
  "esx:getSharedObject",
  function(obj)
    ESX = obj
  end
)

local isLoggedIn = false

CharData = nil
Callbacks = nil
isPhoneOpen = false

Death = nil
Callbacks = nil
Inventory = nil

AddEventHandler(
  "playerSpawned",
  function()
    chat("Player spawned", {0, 255, 0})
    isLoggedIn = true
    TriggerServerEvent("serverCharacterSpawned")
    SendNUIMessage(
      {
        action = "SetServerID",
        id = GetPlayerServerId(PlayerId())
      }
    )
  end
)

RegisterNetEvent("playerLogout")
AddEventHandler(
  "playerLogout",
  function()
    isLoggedIn = false
    SendNUIMessage(
      {
        action = "Logout"
      }
    )
  end
)

RegisterNetEvent("mythic_phone:client:TogglePhone")
AddEventHandler(
  "mythic_phone:client:TogglePhone",
  function(identifier, data)
    TogglePhone()
  end
)

RegisterNetEvent("mythic_phone:client:SetupData")
AddEventHandler(
  "mythic_phone:client:SetupData",
  function(data)
    chat("DATA FROM CLIENT SETUPD DATA", {0, 255, 0})
    chat(data[1].data.name, {0, 255, 0})
    chat(data[1].data.phone, {0, 255, 0})
    SendNUIMessage(
      {
        action = "setup",
        data = data
      }
    )
  end
)

function DrawUIText(text, font, centre, x, y, scale, r, g, b, a)
  SetTextFont(font)
  SetTextProportional(0)
  SetTextScale(scale, scale)
  SetTextColour(r, g, b, a)
  SetTextDropShadow(0, 0, 0, 0, 255)
  SetTextEdge(1, 0, 0, 0, 255)
  SetTextDropShadow()
  SetTextOutline()
  SetTextCentre(centre)
  SetTextEntry("STRING")
  AddTextComponentString(text)
  DrawText(x, y)
end

function CalculateTimeToDisplay()
  hour = GetClockHours()
  minute = GetClockMinutes()

  local obj = {}

  if hour <= 9 then
    hour = "0" .. hour
  end

  if minute <= 9 then
    minute = "0" .. minute
  end

  obj.hour = hour
  obj.minute = minute

  return obj
end

local counter = 0
Citizen.CreateThread(
  function()
    while true do
      if IsDisabledControlJustReleased(1, 170) or IsControlJustReleased(1, 170) then
        TriggerEvent("chatMessage", "[Server]", {255, 255, 0}, "Key Pressed")
        -- TriggerServerEvent("checkForPhone") -- Eventually check if person has a phone
        TriggerEvent("togglePhone")
      end

      if isPhoneOpen then
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 245, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 199, true)
        DisableControlAction(0, 26, true)
        DisableControlAction(0, 0, true)
        DisableControlAction(0, 37, true) -- Weapon wheel scroll
      end

      if counter <= 0 then
        local time = CalculateTimeToDisplay()
        SendNUIMessage(
          {
            action = "updateTime",
            time = time.hour .. ":" .. time.minute
          }
        )
        counter = 50
      else
        counter = counter - 1
      end

      Citizen.Wait(1)
    end
  end
)

-- Uncomment this when phone is an item
-- RegisterNetEvent("noPhone")
-- AddEventHandler(
--   "noPhone",
--   function()
--     exports["mythic_notify"]:SendAlert("error", "No phone")
--   end
-- )

RegisterNetEvent("togglePhone")
AddEventHandler(
  "togglePhone",
  function()
    TriggerEvent(
      "chatMessage",
      "[Server]",
      {255, 255, 0},
      "------------------------ TOGGLE PHONE ------------------------"
    )
    exports["mythic_notify"]:SendAlert("inform", "toggle phone")
    if not openingCd or isPhoneOpen then
      isPhoneOpen = not isPhoneOpen
      if isPhoneOpen then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        if Call ~= nil then
          SendNUIMessage({action = "show", number = Call.number, initiator = Call.initiator})
        else
          SendNUIMessage({action = "show"})
        end
        PhonePlayIn()

        TriggerEvent("chatMessage", "[Server]", {255, 0, 0}, "Open Phone")
      else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        if not IsInCall() then
          PhonePlayOut()
        end
        SendNUIMessage({action = "hide"})
        TriggerEvent("chatMessage", "[Server]", {255, 0, 0}, "Close Phone")
      end

      if not IsPedInAnyVehicle(PlayerPedId(), true) then
        DisplayRadar(isPhoneOpen)
      end

      openingCd = true
    end

    Citizen.CreateThread(
      function()
        Citizen.Wait(2000)
        openingCd = false
      end
    )
  end
)

function ForceClosePhone()
  isPhoneOpen = false
  SetNuiFocus(isPhoneOpen, isPhoneOpen)
  if not IsInCall() then
    PhonePlayOut()
  end
  SendNUIMessage({action = "hide"})
end

RegisterNetEvent("mythic_phone:client:SetAppState")
AddEventHandler(
  "mythic_phone:client:SetAppState",
  function(apps)
    for k, v in pairs(Config.Apps) do
      if apps[v.container] ~= nil then
        v.enabled = apps[v.container]
        SendNUIMessage(
          {
            action = "EditAppState",
            app = v.container,
            state = v.enabled
          }
        )
      end
    end
  end
)

RegisterNetEvent("mythic_phone:client:EditAppState")
AddEventHandler(
  "mythic_phone:client:EditAppState",
  function(app, state)
    for k, v in pairs(Config.Apps) do
      if v.container == app then
        v.enabled = state
        SendNUIMessage(
          {
            action = "EditAppState",
            app = app,
            state = state
          }
        )
      end
    end
  end
)

RegisterNUICallback(
  "RegisterData",
  function(data, cb)
    ESX.TriggerServerCallback(
      "mythic_phone:server:RegisterData",
      {
        key = data.key,
        data = data.data
      }
    )
    cb(true)
  end
)

RegisterNUICallback(
  "GetData",
  function(data, cb)
    ESX.TriggerServerCallback(
      "mythic_phone:server:GetData",
      function(data)
        cb(data)
      end,
      {
        key = data.key
      }
    )
  end
)

RegisterNUICallback(
  "log",
  function(data)
    chat(data.text, {255, 0, 0})
  end
)

RegisterNUICallback(
  "ClosePhone",
  function(data, cb)
    chat("we in here trying to close phone", {0, 255, 0})
    if not isPhoneOpen then
      return
    end
    TriggerEvent("togglePhone")
  end
)

function chat(str, color)
  TriggerEvent("chat:addMessage", {color = color, multiline = true, args = {str}})
end
