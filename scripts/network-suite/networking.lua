-- network-suite/networking.lua
-- Copyright (c) 2024 Luke Harding
-- This code is licensed under a MIT license.

local component = require("component");
local serialization = require("serialization");
local fs = require("filesystem");
local event = require("event");

local addrs = {};

local networkProtocolPort = 1;
local networkConfigLocation = "/etc/network";
local addrConfigName = "addr.cfg";

function start()
  fs.makeDirectory(networkConfigLocation);

  local modems = component.list("modem");
  local addrConfigLocation = fs.concat(networkConfigLocation, addrConfigName);
  local addrConfigFile = io.open(addrConfigLocation, "r");

  if addrConfigFile then
    local content = addrConfigFile:read("*a");
    if content and content ~= "" then
      local storedAddrs = serialization.unserialize(content);
      addrConfigFile:close();
      for id, addr in pairs(storedAddrs) do
        if modems[id] then
          addrs[id] = addr;
        end
      end
    end
  end

  for id, _ in modems do
    if not addrs[id] then
      addrs[id] = "";
    elseif addrs[id] ~= "" then
      component.invoke(id, "open", networkProtocolPort);
    end
  end

  local writeHandle = io.open(addrConfigLocation, "w");

  if writeHandle then
    local content = serialization.serialize(addrs);
    writeHandle:write(content):flush();
    writeHandle:close();
  end
end

function stop()
  for id, addr in pairs(addrs) do
    if addr ~= "" then
      component.invoke(id, "close", networkProtocolPort);
    end
  end
end

function reload()
  stop();
  start();
end
