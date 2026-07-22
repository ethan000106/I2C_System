markdown

<div align="center">

\# 🤝 MicroBlaze \& FPGA I2C Master-Slave Communication System

!\[Language](https://img.shields.io/badge/Language-SystemVerilog%20%2F%20Verilog-blue?style=for-the-badge)

!\[Processor](https://img.shields.io/badge/Processor-MicroBlaze-orange?style=for-the-badge)

!\[Protocol](https://img.shields.io/badge/Protocol-I2C%20Standard-purple?style=for-the-badge)

!\[License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

\*\*MicroBlaze 임베디드 코어(Master)와 Custom FPGA Logic(Slave) 간의 I2C 프로토콜 통신 통합 검증 프로젝트\*\*

</div>

\---

\## ✨ Key Features

| 항목 | 설명 |

| :--- | :--- |

| 👑 \*\*I2C Master System\*\* | MicroBlaze 임베디드 프로세서 및 Xilinx I2C IP 기반의 Master Controller |

| 🛡️ \*\*I2C Slave Module\*\* | Start/Stop 조건 감지, 7-bit 주소 매칭, Read/Write 수신 지원 Custom Slave RTL |

| 🔄 \*\*Full-Duplex Verification\*\* | Master와 Slave 간의 데이터 송수신 동작 검증 및 ACK/NACK 처리 |

\---

\## 📂 Directory Structure

```text

📦 i2c\_system

&#x20;┣ 📂 rtl

&#x20;┃ ┣ 📂 master           # MicroBlaze \& I2C Master RTL 소스

&#x20;┃ ┗ 📂 slave            # Custom I2C Slave RTL 소스

&#x20;┣ 📂 tb                 # Master-Slave 통합 Testbench

&#x20;┣ 📂 docs               # 시스템 아키텍처 \& 타이밍 다이어그램

&#x20;┗ 📜 .gitignore         # Vivado 빌드 정크 필터

👨‍💻 Author

GitHub: @ethan000106

