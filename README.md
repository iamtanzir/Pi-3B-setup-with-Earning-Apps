# Pi-3B-setup-with-Earning-Apps
Pi 3B setup with (Pi-hole+Honeygain+EarnApp)

Raspberry Pi 3B সেটআপ করতে চাই নিচের স্পেসিফিকেশনে:
🎯 লক্ষ্য:
- Raspberry Pi 3B মডেল
- SSD থেকে বুট (USB বুট)
- Raspberry Pi OS 64-bit (Lite ভার্সন)
- Pi-hole (Docker container হিসেবে)
- Honeygain (Docker-এ, amd64 emulation ব্যবহার করে)
- EarnApp (নেটিভ systemd সার্ভিস হিসেবে, Docker ছাড়া)

📋 নির্দিষ্ট প্রয়োজনীয়তা:
হার্ডওয়্যার:
1. 120GB SATA SSD
2. USB 3.0 থেকে SATA অ্যাডাপ্টার (UASP সাপোর্টেড হলে ভালো)
3. Raspberry Pi 3B
4. 5V 2.5A পাওয়ার অ্যাডাপ্টার
5. Passive heatsink
সফটওয়্যার:
1. Raspberry Pi OS Lite 64-bit
2. Docker (Pi-hole ও Honeygain-এর জন্য)
3. amd64 emulation (Honeygain-এর জন্য - কারণ Honeygain শুধু amd64 ইমেজ সরবরাহ করে)

🚀 Step-by-Step গাইড চাই:
Part 1: USB Boot Enable (One-time, microSD ব্যবহার করে)
- Raspberry Pi Imager দিয়ে microSD-তে Raspberry Pi OS Lite 64-bit ফ্লাশ করা
- রাস্পবেরিতে বুট করে USB Boot enable করা
- OTP প্রোগ্রামিং নিশ্চিত করা
Part 2: SSD-তে OS ইনস্টলেশন
- SSD-তে Raspberry Pi OS Lite 64-bit ফ্লাশ করা
- Pi-তে SSD সংযোগ এবং SSD থেকে বুট নিশ্চিত করা
Part 3: Base OS সেটআপ
- আপডেট, আপগ্রেড
- Locale ও timezone সেটআপ (Asia/Dhaka)
- SSH enable করা
- Hostname সেট করা
Part 4: Docker ইনস্টলেশন (64-bit)
- Docker install ও user group-এ যোগ করা
Part 5: Pi-hole (Docker-এ)
- Pi-hole container চালানো
- Port ম্যাপিং (53/tcp, 53/udp, 80/tcp)
- Admin UI access নিশ্চিত করা
 Part 6: Honeygain (Docker with amd64 emulation)
- binfmt ব্যবহার করে amd64 emulation enable করা
- Honeygain container চালানো (linux/amd64 platform নির্দিষ্ট করে)
- Credentials যোগ করা
- Resource limits সেট করা
 Part 7: EarnApp (Native system service)
- EarnApp install script রান করা
- Device পেয়ারিং করা
- systemd service হিসেবে চালানো নিশ্চিত করা
 Part 8: মনিটরিং ও মেইনটেন্যান্স
- তাপমাত্রা মনিটরিং
- Service স্বাস্থ্য চেক
- স্বয়ংক্রিয় রিস্টার্ট কনফিগার
Part 9: ট্রাবলশ্যুটিং
- USB boot সমস্যা
- Container networking সমস্যা
- EarnApp পেয়ারিং সমস্যা

🎯 বিশেষ নোট:
1. সবকিছু 64-bit compatible হতে হবে (EarnApp 64-bit ছাড়া চলে না)
2. Honeygain-কে amd64 emulation-এ চালাতে হবে
3. Production-grade, policy-compliant সলিউশন চাই
4. সব steps শূন্য থেকে শুরু করতে হবে (beginner-friendly)
5. Resource optimization (Pi 3B-এর সীমিত resources মাথায় রেখে)

📊 চূড়ান্ত আর্কিটেকচার:

SSD Boot
├── Raspberry Pi OS Lite 64-bit
│   ├── Docker
│   │   ├── Pi-hole container
│   │   └── Honeygain container (amd64 emulated)
│   └── EarnApp (native systemd service)

```
❗ Policy কম্প্লায়েন্স:
- Pi-hole: Fully supported
- Honeygain: Docker ব্যবহারে কোনো policy issue নেই
- EarnApp: Native installation, তাদের terms মেনে
