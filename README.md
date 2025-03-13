# Övning: Skapa EC2-instanser i Publikt och Privat Subnät med OpenTofu

## Mål
Denna övning hjälper dig att förstå hur du:
1. Skapar en **VPC** med subnät manuellt i AWS Console.
2. Använder **OpenTofu** i AWS CloudShell för att skapa EC2-instanser.
3. Skapar en **publik EC2-instans** som kan nå en **privat EC2-instans** via SSH.
4. Konfigurerar en **Internet Gateway** och **NAT Gateway** för kommunikation.

---

## **Steg 1: Skapa Nätverksresurser manuellt i AWS Console**
Gå till **AWS Console** och skapa följande resurser manuellt:

### **1.1 Skapa en VPC**
1. Navigera till **Your VPCs**.
2. Klicka **Create VPC**.
3. Ange namn: `mar13-vpc`.
4. IPv4 CIDR Block: `10.0.0.0/16`.
5. Klicka **Create VPC**.

### **1.2 Skapa Subnät**
1. Gå till **Subnets** i VPC Dashboard.
2. Klicka **Create subnet**.
3. Välj `mar13-vpc`.

#### **Publikt subnät**
- Namn: `mar13-public-subnet`
- Välj en Availability Zone (AZ) (tex: `us-east-1a`)
- IPv4 subnet CIDR block: `10.0.1.0/24`
- Klicka **Create subnet**

#### **Privat subnät**
- Namn: `mar13-private-subnet`
- Välj samma AZ som ovan
- IPv4 subnet CIDR block: `10.0.2.0/24`
- Klicka **Create subnet**

### **1.3 Skapa och anslut en Internet Gateway**
1. Gå till **Internet Gateways**.
2. Klicka **Create Internet Gateway**.
3. Namn: `mar13-igw`.
4. Klicka **Create Internet Gateway**.
5. Klicka **Actions > Attach to VPC**, välj `mar13-vpc`, klicka **Attach**.

### **1.4 Uppdatera Routing Tabeller**
#### **Publikt subnät**
1. Gå till **Route Tables** i VPC Dashboard.
2. Identifiera och klicka på **default route table** för `mar13-vpc`.
3. Klicka på **Edit routes > Add route**:
   - **Destination:** `0.0.0.0/0`
   - **Target:** Internet Gateway → `mar13-igw`
4. Klicka **Save changes**.
5. Gå till **Subnet Associations** för denna route table och **se till att endast** `mar13-public-subnet` är associerat.

#### **Privat subnät**
1. Gå tillbaka till **Route Tables** och klicka **Create route table**.
   - **Name:** `mar13-private-route-table`
   - **VPC:** `mar13-vpc`
2. Klicka **Create** och öppna den nya route-tabellen.
3. Klicka **Save changes**.
4. Gå till **Subnet Associations** och associera denna route table med `mar13-private-subnet`.

### **Varför behövs detta?**
- **Det publika subnätet** behöver en väg till internet via Internet Gateway.
- **Det privata subnätet** ska inte ha direkt internetåtkomst. Istället kan det använda en NAT Gateway (om det behöver utgående internetåtkomst) eller lämnas utan internetåtkomst.

Nu bör ditt privata subnät vara korrekt isolerat, och instansen i det publika subnätet kan fungera för att nå den privata instansen.

---

## **Steg 2: Skapa EC2-instanser med OpenTofu**

1. Klona repo och navigera till projektmappen:
   ```bash
   git clone https://github.com/khdev-devops/infra-mar13-networking
   ```
   ```bash
   cd infra-mar13-networking
   ```

2. Installera OpenTofu i AWS CloudShell
   AWS CloudShell har redan nödvändiga AWS-behörigheter, så vi kan installera och köra OpenTofu direkt.

   Installera OpenTofu i CloudShell (behövs göras då och då eftersom CloudShell inte sparar installationer av paker och mjukvara):
   ```bash
   ./install_tofu.sh
   ```
   Kontrollera att OpenTofu är installerat:
   ```bash
   tofu --version
   ```

3. Skapa nycklar för att användas vid anslutaning till EC2 med SSH:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/tofu-key -N ""
   ```

4. Skapa din egen `terraform.tfvars`
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   - Editera `terraform.tfvars` och sätt CloudShell-IP (`curl ifconfig.me`) du vill ska kunna nå den publika EC-instansen med SSH

5. **Initiera OpenTofu:**
   ```sh
   tofu init
   tofu plan
   tofu apply
   ```
   - Fick du felet att det är slut på utrymme på CloudShell? Kör då `./tofu_init.sh`som rensar bort och ser till att OpenTofu använder plugins mellan de olika projekten (vilket sparar utrymme). Du kan behöva köra `tofu init`igen efter detta.

6. **Notera de IP-adresser som visas i resultatet**  
   - **Public Instance IP:** `X.X.X.X`
   - **Private Instance IP:** `Y.Y.Y.Y`

---

## **Steg 3: Testa SSH mellan instanser (med SSH Agent Forwarding)**

1. **Starta SSH-agenten och lägg till din nyckel:**
För att kunna vidarebefordra nyckeln (SSH Agent Forwarding) gör följande:
```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/tofu-key
```

2.**Anslut till den publika instansen med agent forwarding**
```sh
ssh -A ec2-user@<public-instance-ip>
```
- **`-A` flaggan möjliggör agent forwarding**, vilket innebär att vi kan använda vår SSH-nyckel från CloudShell hela vägen till den privata instansen.

3. **Från den publika instansen, SSH till den privata instansen**
När du är inne på bastion-hosten (den publika EC2-instansen), använd följande kommando:
```sh
ssh ec2-user@<private-instance-ip>
```
- Observera att du inte behöver använda `-i ~/.ssh/tofu-key` här**, eftersom vi använder **SSH-agent forwarding**.

Gick det? **Grattis!** Du har nu skapat en privat och en publik EC2-instans via OpenTofu och konfigurerat en bastion-host för SSH åtkomst!

---

## **Steg 4: Rensa upp resurser**

För att ta bort instanserna med OpenTofu:
```sh
tofu destroy
```
För att ta bort VPC och subnät, gå till **AWS Console** och radera dem manuellt.
