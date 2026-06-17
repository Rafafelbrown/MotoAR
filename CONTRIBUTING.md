# Contribuindo para MotoAR

Obrigado por seu interesse em contribuir! Este documento fornece diretrizes e instruções para colaborar com o projeto.

## 🚀 Como Começar

1. **Fork o repositório** - Clique no botão "Fork" no GitHub
2. **Clone seu fork**:
   ```bash
   git clone https://github.com/seu-usuario/motoar.git
   cd motoar
   ```

3. **Configure o upstream**:
   ```bash
   git remote add upstream https://github.com/original-repo/motoar.git
   ```

4. **Crie uma branch para sua feature**:
   ```bash
   git checkout -b feature/sua-feature
   ```

## 📋 Desenvolvimento

### Setup do Ambiente

```bash
# Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # macOS/Linux
# ou
.\venv\Scripts\Activate.ps1  # Windows

# Instalar dependências
pip install -r requirements.txt

# Instalar dependências de desenvolvimento (React)
cd dashboard/react
npm install
cd ../..
```

### Executar o Projeto

```bash
# Pipeline
python pipeline/orchestration/run_pipeline.py

# Streamlit
streamlit run dashboard/streamlit/motoar_app.py

# React (em outro terminal)
cd dashboard/react
npm run dev
```

### Testes

```bash
# Rodar todos os testes
pytest

# Com cobertura
pytest --cov=pipeline tests/

# Teste específico
pytest tests/test_motoar.py::test_name
```

## 📝 Regras de Commit

- Use mensagens claras e descritivas em português
- Prefixos recomendados:
  - `feat:` - Nova funcionalidade
  - `fix:` - Correção de bug
  - `docs:` - Documentação
  - `test:` - Testes
  - `refactor:` - Refatoração de código
  - `infra:` - Mudanças de infraestrutura

Exemplo:
```bash
git commit -m "feat: adicionar validação de qualidade de ar"
```

## 🔄 Submetendo uma Pull Request

1. **Faça push de sua branch**:
   ```bash
   git push origin feature/sua-feature
   ```

2. **Crie uma Pull Request** no GitHub com:
   - Título claro e descritivo
   - Descrição do que foi mudado
   - Referência a issues relacionadas (ex: `Closes #123`)

3. **Checklist antes de submeter**:
   - [ ] Código segue o estilo do projeto
   - [ ] Testes foram criados/atualizados
   - [ ] Documentação foi atualizada
   - [ ] Sem console errors ou warnings
   - [ ] Testado localmente

## 🐛 Reportando Issues

Use a seção "Issues" para reportar bugs:

- **Título**: Resumo claro do problema
- **Descrição**: 
  - Passos para reproduzir
  - Comportamento esperado
  - Comportamento atual
  - Screenshots (se aplicável)
  - Ambiente (OS, Python version, etc)

## 📚 Estrutura do Projeto

```
motoar/
├── pipeline/          # ETL e ML
│   ├── bronze/       # Ingestão raw
│   ├── silver/       # Limpeza
│   ├── gold/         # Agregações
│   ├── quality/      # Validações
│   └── orchestration/# Orquestração
├── dashboard/        # Frontends
│   ├── react/        # Dashboard web
│   └── streamlit/    # Análises
├── infra/            # Docker, K8s
├── tests/            # Testes
├── docs/             # Documentação
└── data/             # Dados (não versionados)
```

## 💡 Dicas

- Mantenha PRs pequenas e focadas
- Rebase com `main` antes de submeter
- Revise seu próprio código primeiro
- Seja respeitoso com reviewers

## ❓ Dúvidas?

- Abra uma issue com a tag `question`
- Consulte o README.md
- Veja as discussões existentes

Obrigado por contribuir! 🎉
