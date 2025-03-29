# 🖼️ Gemini Vision - Desktop Financial Chart Analyzer 🧠

[![Python Version][python-shield]][python-url]
[![PyQt5 Version][pyqt-shield]][pyqt-url]
[![Google AI SDK][googleai-shield]][googleai-url]
[![License: MIT][license-shield]][license-url]
[![Project Status: Active][status-shield]][status-url]
[![Last Commit][last-commit-shield]][last-commit-url]
[![Code Style: Black][code-style-shield]][code-style-url]

**Análise técnica de gráficos financeiros turbinada por Inteligência Artificial diretamente no seu Desktop!** ✨

Este aplicativo de desktop, construído com Python e PyQt5, utiliza o poder da API Google Gemini (especificamente seus modelos Vision) para realizar análises técnicas aprofundadas em imagens de gráficos financeiros (ações, criptomoedas, etc.). Arraste e solte suas imagens, escolha o modelo Gemini desejado e receba uma análise detalhada focada em *price action*, padrões, tendências e mais, formatada em Markdown e salva automaticamente junto com as imagens originais.

---

## 🌟 Principais Funcionalidades

*   **✨ Interface Intuitiva Drag & Drop:** Arraste e solte facilmente uma ou múltiplas imagens de gráficos diretamente na aplicação.
*   **🔑 Gerenciamento Seguro de API Key:** Sua chave da API Google Gemini é armazenada localmente de forma segura em um arquivo `config.yaml`.
*   **🤖 Seleção Flexível de Modelos Gemini:** Escolha entre diversos modelos Gemini (incluindo Flash, Pro e experimentais) para ajustar a análise às suas necessidades.
*   **📊 Análise Técnica Automatizada:** Receba análises detalhadas focadas em:
    *   Padrões de Candlestick e Gráficos
    *   Identificação de Tendências (Alta, Baixa, Lateral)
    *   Níveis de Suporte e Resistência
    *   Padrões de Price Action (Reversão, Continuação)
    *   Análise de Volume
    *   Interpretação Técnica e Cenários Futuros
    *   Sugestões Acionáveis (pontos de entrada/saída, stop-loss - *educacional*)
*   **🖼️ Geração Automática de Colagem:** Múltiplas imagens são combinadas em uma única colagem antes do envio para a API, otimizando a análise.
*   **📝 Saída em Markdown Rico:** A análise gerada pela IA é formatada em Markdown, pronta para leitura ou uso em outras ferramentas.
*   **📁 Organização Automática de Projetos:** Cada análise gera uma pasta única contendo o arquivo `.md` da análise e cópias das imagens originais utilizadas.
*   **🎨 Interface Moderna e Responsiva:** UI limpa e agradável construída com PyQt5.
*   **📄 Logging Detalhado:** Registra eventos importantes e erros no arquivo `image_analysis_app.log` para fácil depuração.

---

## 🛠️ Tecnologias e Bibliotecas Utilizadas

| Tecnologia / Biblioteca       | Ícone | Descrição                                                                 |
| :---------------------------- | :---: | :------------------------------------------------------------------------ |
| **Python**                    |  🐍   | Linguagem principal de desenvolvimento.                                   |
| **PyQt5**                     |  🎨   | Framework para a criação da interface gráfica do usuário (GUI).             |
| **Google Generative AI (SDK)**| ✨🧠  | Biblioteca oficial para interagir com a API Google Gemini (incluindo Vision). |
| **Pillow (PIL Fork)**         |  🖼️   | Biblioteca para manipulação de imagens (criação de colagens).              |
| **PyYAML**                    |  ⚙️   | Biblioteca para ler e escrever arquivos de configuração YAML (API Key).    |
| **Colorama**                  |  🌈   | Para adicionar cores estilizadas às mensagens no console (opcional/debug). |
| **Standard Libraries**        |  📚   | `os`, `sys`, `datetime`, `shutil`, `logging`, `base64`, `re`, `io`, etc.   |

---

## 🚀 Instalação

Siga estes passos para configurar e rodar o projeto localmente:

1.  **Clone o Repositório:**
    ```bash
    git clone https://github.com/chaos4455/Gemini-Deskop-LVM-APP.git
    cd Gemini-Deskop-LVM-APP
    ```

2.  **Crie um Ambiente Virtual (Recomendado):**
    ```bash
    # Windows
    python -m venv venv
    .\venv\Scripts\activate

    # macOS / Linux
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Instale as Dependências:**
    *Certifique-se de ter um arquivo `requirements.txt` no seu repositório com as bibliotecas listadas acima.*
    ```bash
    pip install -r requirements.txt
    ```
    *(Se você não tiver um `requirements.txt`, crie um com o conteúdo abaixo e depois rode o `pip install`)*
    ```txt
    # requirements.txt
    PyQt5
    google-generativeai
    Pillow
    PyYAML
    colorama
    ```

4.  **Configure sua API Key:**
    *   Obtenha sua API Key do Google Gemini em [Google AI Studio](https://aistudio.google.com/app/apikey).
    *   Na primeira vez que executar a aplicação, você será solicitado a inserir a API Key na interface gráfica. Ela será salva no arquivo `config.yaml`. Alternativamente, você pode criar o arquivo `config.yaml` manualmente na raiz do projeto com o seguinte conteúdo:
        ```yaml
        api_key: SUA_API_KEY_AQUI
        ```

---

## ▶️ Como Usar

1.  **Execute a Aplicação:**
    ```bash
    python seu_script_principal.py # Substitua pelo nome do seu arquivo principal, ex: main.py, app.py
    ```

2.  **Insira a API Key (se solicitado):** Cole sua API Key do Google Gemini no campo superior e a aplicação tentará inicializar a sessão.

3.  **Selecione o Modelo Gemini:** Escolha o modelo de IA desejado no menu dropdown. A aplicação se reconfigurará automaticamente.

4.  **Adicione Imagens:** Arraste e solte uma ou mais imagens de gráficos financeiros (formatos suportados: `.jpg`, `.jpeg`, `.png`, `.gif`) na área designada "Arraste e solte imagens aqui 🖼️". As imagens aparecerão na lista.

5.  **Inicie a Análise:** Clique no botão **"Analisar Imagens ✨"**.
    *   As imagens serão combinadas em uma colagem (se houver mais de uma).
    *   A colagem e o prompt de análise serão enviados para a API Gemini.
    *   A barra de progresso indicará a atividade (atualmente simplificada).

6.  **Visualize o Resultado:** A análise detalhada gerada pela IA aparecerá na área de texto inferior.

7.  **Acesse os Arquivos Salvos:** Uma nova pasta será criada na raiz do projeto (ex: `gemini_analysis_project_20250315_103000`). Dentro dela, você encontrará:
    *   Um arquivo `.md` contendo a análise completa.
    *   Cópias das imagens originais que você utilizou para a análise.

8.  **Limpar:** Use o botão **"Limpar Lista 🧹"** para remover as imagens da lista atual e limpar a área de resultados.

---
## 🔮 Possíveis Melhorias Futuras

*   [ ] Barra de progresso mais granular durante a análise.
*   [ ] Opção para editar o prompt enviado à IA.
*   [ ] Pré-visualização da colagem de imagens.
*   [ ] Opção para salvar/carregar configurações de análise (modelo preferido, etc.).
*   [ ] Melhor tratamento de erros de rede e da API.
*   [ ] Internacionalização (suporte a outros idiomas na UI).
*   [ ] Empacotamento da aplicação em um executável (usando PyInstaller ou similar).

---

## 🤝 Contribuições

Contribuições são bem-vindas! Se você tiver sugestões, correções de bugs ou novas funcionalidades, sinta-se à vontade para:

1.  Fazer um Fork do repositório.
2.  Criar uma nova Branch (`git checkout -b feature/sua-feature` ou `bugfix/seu-bugfix`).
3.  Fazer commit das suas alterações (`git commit -m 'Adiciona nova feature X'`).
4.  Fazer Push para a Branch (`git push origin feature/sua-feature`).
5.  Abrir um Pull Request.

---

## 📄 Licença

Este projeto está licenciado sob a **Licença MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes (você precisará criar este arquivo se escolher a licença MIT).

[![License: MIT][license-shield]][license-url]

---

## 👤 Autor

Criado com ❤️ por **Elias Andrade**

*   📍 Maringá, Paraná - Brasil 🇧🇷
*   📅 Março 2025
*   🐙 GitHub: [chaos4455](https://github.com/chaos4455)
*   🔗 Repositório do Projeto: [https://github.com/chaos4455/Gemini-Deskop-LVM-APP](https://github.com/chaos4455/Gemini-Deskop-LVM-APP)

---

*Disclaimer: As análises financeiras geradas por IA são para fins educacionais e informativos. Não constituem aconselhamento financeiro. Sempre faça sua própria pesquisa (DYOR) e consulte um profissional qualificado antes de tomar decisões de investimento.*

<!-- Shields/Badges Definitions (use shields.io - customize colors and details as needed) -->
[python-shield]: https://img.shields.io/badge/Python-3.8%2B-8A2BE2?style=for-the-badge&logo=python&logoColor=white
[python-url]: https://www.python.org/
[pyqt-shield]: https://img.shields.io/badge/PyQt5-5.15%2B-8A2BE2?style=for-the-badge&logo=qt&logoColor=white
[pyqt-url]: https://riverbankcomputing.com/software/pyqt/
[googleai-shield]: https://img.shields.io/badge/Google%20AI%20SDK-Latest-8A2BE2?style=for-the-badge&logo=googlecloud&logoColor=white
[googleai-url]: https://github.com/google/generative-ai-python
[license-shield]: https://img.shields.io/badge/License-MIT-8A2BE2?style=for-the-badge
[license-url]: https://opensource.org/licenses/MIT
[status-shield]: https://img.shields.io/badge/Status-Active-8A2BE2?style=for-the-badge
[status-url]: #
[last-commit-shield]: https://img.shields.io/github/last-commit/chaos4455/Gemini-Deskop-LVM-APP?color=8A2BE2&style=for-the-badge
[last-commit-url]: https://github.com/chaos4455/Gemini-Deskop-LVM-APP/commits/main
[code-style-shield]: https://img.shields.io/badge/Code%20Style-Black-8A2BE2?style=for-the-badge
[code-style-url]: https://github.com/psf/black
