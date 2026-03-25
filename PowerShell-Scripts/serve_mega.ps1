Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class MegaHttp {
    public static void Start() {
        TcpListener listener = new TcpListener(IPAddress.Any, 8080);
        listener.Start();
        while (true) {
            TcpClient client = listener.AcceptTcpClient();
            NetworkStream stream = client.GetStream();
            StreamReader reader = new StreamReader(stream);
            string request = reader.ReadLine();
            
            string script = "#!/bin/bash\n" +
                "echo 'FINAL MEGA SETUP IN PROGRESS...'\n" +
                "getuto\n" +
                "mkdir -p /etc/portage/package.accept_keywords\n" +
                "echo \"gnome-extra/cinnamon ~amd64\" >> /etc/portage/package.accept_keywords/final\n" +
                "echo \"gnome-extra/cinnamon-translations ~amd64\" >> /etc/portage/package.accept_keywords/final\n" +
                "echo \"x11-wm/muffin ~amd64\" >> /etc/portage/package.accept_keywords/final\n" +
                "echo \"gnome-extra/cinnamon-desktop ~amd64\" >> /etc/portage/package.accept_keywords/final\n" +
                "echo \"x11-misc/lightdm ~amd64\" >> /etc/portage/package.accept_keywords/final\n" +
                "etc-update --automode -5\n" +
                "export MAKEOPTS=\"-j4\"\n" +
                "emerge --getbinpkg -v gnome-extra/cinnamon gnome-extra/cinnamon-translations x11-misc/lightdm sys-boot/grub dev-vcs/git\n" +
                "echo 'Configuring Bootloader...'\n" +
                "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB\n" +
                "grub-mkconfig -o /boot/grub/grub.cfg\n" +
                "echo 'Setting passwords...'\n" +
                "echo \"root:abdallah\" | chpasswd\n" +
                "useradd -m -G wheel,video,audio -s /bin/bash abdallah\n" +
                "echo \"abdallah:abdallah\" | chpasswd\n" +
                "echo 'Configuring fstab...'\n" +
                "echo \"/dev/sda1 /boot vfat defaults 0 2\" > /etc/fstab\n" +
                "echo \"/dev/sda2 / ext4 noatime 0 1\" >> /etc/fstab\n" +
                "echo 'Enabling services...'\n" +
                "rc-update add lightdm default\n" +
                "rc-update add dbus default\n" +
                "rc-update add NetworkManager default\n" +
                "echo 'DONE! REBOOT NOW.'\n";
            script = script.Replace("\r", "");
            
            byte[] content = Encoding.UTF8.GetBytes(script);
            string header = "HTTP/1.1 200 OK\r\nContent-Length: " + content.Length + "\r\nConnection: close\r\n\r\n";
            byte[] headBytes = Encoding.UTF8.GetBytes(header);
            stream.Write(headBytes, 0, headBytes.Length);
            stream.Write(content, 0, content.Length);
            stream.Flush();
            client.Close();
            break;
        }
        listener.Stop();
    }
}
"@
[MegaHttp]::Start()
