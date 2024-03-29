import {
  ButtplugClient,
  ButtplugBrowserWebsocketClientConnector,
} from "buttplug";

const Hub = () => {
  const client = new ButtplugClient("IntisyncClient");

  const connect = async (view, address) => {
    try {
      const connector = new ButtplugBrowserWebsocketClientConnector(address);

      await client.connect(connector);

      const intervalID = setInterval(() => {
        if (client.connected) return;
        view.pushEvent("disconnected", {});
        clearInterval(intervalID);
      }, 1000);

      view.pushEvent("connected", {});
    } catch (e) {
      view.pushEvent("connect_error", {});
    }
  };

  return {
    mounted() {
      this.handleEvent("vibrate", async ({ index, vibration }) => {
        const device = client.devices.find((d) => d.index == index);
        if (device === undefined) return;
        await device.vibrate(vibration / 100.0);
      });

      this.handleEvent("connect", async ({ url }) => await connect(this, url));

      client.addListener("deviceadded", async (device) => {
        const event = {
          index: device.index,
          name: device.name,
        };

        this.pushEvent("device_connected", event);
      });

      client.addListener("deviceremoved", async (device) => {
        this.pushEvent("device_disconnected", { index: device.index });
      });
    },
  };
};

export default Hub;
