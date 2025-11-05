# PostgreSQL with pgTAP - Multi-Version Docker Images

Ready-to-use PostgreSQL containers with pgTAP testing framework pre-installed. Supports PostgreSQL 18 & 17 with multi-platform builds.

## 🚀 Quick Start

```bash
# Pull and run PostgreSQL 18 with pgTAP
docker run -d --name postgres-pgtap \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  pshaddel/postgres-pgtap:latest

# Verify pgTAP is working
docker exec -it postgres-pgtap psql -U postgres -c "SELECT pgtap_version();"
```

## 📋 Available Tags

### PostgreSQL 18 (Latest)
- `latest`, `18`, `18.0` - Standard Debian-based
- `bookworm`, `18-bookworm` - Debian Bookworm
- `trixie`, `18-trixie` - Debian Trixie

### PostgreSQL 17
- `17`, `17.6` - Standard Debian-based
- `17-bookworm` - Debian Bookworm
- `17-trixie` - Debian Trixie

## ✨ Features

- **🧪 pgTAP 1.3** - Full testing framework pre-installed
- **🌍 Multi-platform** - AMD64, ARM64, ARMv7 support
- **🔧 Auto-configured** - Extension enabled on startup
- **🐳 Production-ready** - Based on official PostgreSQL images
- **📦 Multiple variants** - Debian-based options available
- **🔄 Auto-updated** - Latest PostgreSQL versions daily

## 📖 What is pgTAP?

pgTAP brings unit testing to PostgreSQL with TAP (Test Anything Protocol). Write database tests directly in SQL:

```sql
SELECT plan(3);
SELECT ok(true, 'This test passes');
SELECT is(2+2, 4, 'Math works');
SELECT has_table('users', 'Table exists');
SELECT * FROM finish();
```

## 🛠️ Usage Examples

### Basic Setup
```bash
docker run -d --name my-test-db \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=tester \
  -e POSTGRES_PASSWORD=secret \
  -p 5432:5432 \
  pshaddel/postgres-pgtap:latest
```

### With Docker Compose
```yaml
version: '3.8'
services:
  postgres:
    image: pshaddel/postgres-pgtap:latest
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: developer
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./tests:/tests

volumes:
  postgres_data:
```

### Running Tests
```bash
# Run your test files
docker exec -it my-test-db psql -U tester -d testdb -f /tests/my_tests.sql

# Interactive testing
docker exec -it my-test-db psql -U tester -d testdb
```

## 🏗️ Architecture Support

All images support multiple architectures:
- **linux/amd64** - Intel/AMD 64-bit
- **linux/arm64** - ARM 64-bit (Apple Silicon, AWS Graviton)
- **linux/arm/v7** - ARM 32-bit (Raspberry Pi)

## 🔄 Automatic Updates

This repository automatically:
- ✅ Checks for new PostgreSQL releases daily
- ✅ Builds updated images with latest security patches
- ✅ Maintains pgTAP compatibility across versions
- ✅ Supports both PostgreSQL 18 and 17 independently

## 📚 Documentation & Source

- **GitHub Repository**: [pshaddel/postgres-pgtap-docker](https://github.com/pshaddel/postgres-pgtap-docker)
- **pgTAP Documentation**: [pgtap.org](http://pgtap.org/)
- **PostgreSQL Docs**: [postgresql.org](https://www.postgresql.org/docs/)

## 🏷️ Tags Explained

Choose the right image for your needs:
- **Standard tags** (`latest`, `18`): Debian-based, full features
- **Bookworm/Trixie**: Specific Debian versions for compatibility

## 💡 Why Use This Image?

- **Ready to test** - No setup required, pgTAP works immediately
- **CI/CD friendly** - Perfect for automated database testing
- **Multi-platform** - Same image works on Intel, AMD, and ARM
- **Always current** - Automated updates ensure latest PostgreSQL versions
- **Flexible** - Multiple base OS options for different requirements

---

**License**: MIT | **Maintainer**: [pshaddel](https://github.com/pshaddel) | **pgTAP Version**: 1.3