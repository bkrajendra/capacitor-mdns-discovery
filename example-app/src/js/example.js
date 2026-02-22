import { MdnsDiscovery } from 'capacitor-mdns-discovery';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    MdnsDiscovery.echo({ value: inputValue })
}
