import sys
import os
import time
import threading
import logging
import hashlib
import base64
from datetime import datetime
import shutil
from PyQt5.QtWidgets import (QApplication, QWidget, QLabel, QPushButton, QVBoxLayout,
                             QListWidget, QListWidgetItem, QProgressBar, QScrollArea,
                             QTextEdit, QFileDialog, QMessageBox, QHBoxLayout, QLineEdit, QComboBox)  # Import QComboBox
from PyQt5.QtCore import Qt, QSize, QRectF, pyqtSignal, QThreadPool, QRunnable, QObject
from PyQt5.QtGui import QPixmap, QImage, QColor, QDragEnterEvent, QDropEvent, QIcon

from PIL import Image
import io
import google.generativeai as genai
from colorama import Fore, Style, init
import re
import yaml  # Import PyYAML

# Initialize colorama
init(autoreset=True)

# Configure logging
logging.basicConfig(filename="image_analysis_app.log", level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')

# --- API KEY CONFIGURATION ---
CONFIG_FILE = 'config.yaml'


def load_api_key():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            config = yaml.safe_load(f)
            return config.get('api_key')
    return None


def save_api_key(api_key):
    with open(CONFIG_FILE, 'w') as f:
        yaml.dump({'api_key': api_key}, f)


# --- MODEL CONFIGURATION ---
MODEL_OPTIONS = {
    'gemini-2.0-flash': {
        'description': 'Gemini 2.0 Flash',
        'temperature': 0.8,
        'top_p': 0.9,
        'top_k': 40,
        'max_tokens': 8192
    },
    'gemini-2.0-flash-lite-preview-02-05': {
        'description': 'Gemini 2.0 Flash-Lite Preview',
        'temperature': 0.7,  # Adjusted
        'top_p': 0.8,  # Adjusted
        'top_k': 30,  # Adjusted
        'max_tokens': 4096  # Adjusted
    },
    'gemini-1.5-flash': {
        'description': 'Gemini 1.5 Flash',
        'temperature': 0.8,
        'top_p': 0.9,
        'top_k': 40,
        'max_tokens': 8192
    },
    'gemini-1.5-flash-8b': {
        'description': 'Gemini 1.5 Flash-8B',
        'temperature': 0.6,  # Adjusted
        'top_p': 0.7,  # Adjusted
        'top_k': 20,  # Adjusted
        'max_tokens': 2048  # Adjusted
    },
    'gemini-1.5-pro': {
        'description': 'Gemini 1.5 Pro',
        'temperature': 0.9,  # Adjusted
        'top_p': 0.95,  # Adjusted
        'top_k': 50,  # Adjusted
        'max_tokens': 10240  # Adjusted
    },
    'gemini-pro-experimental': {
        'description': 'Gemini Pro Experimental',
        'temperature': 0.9,
        'top_p': 0.95,
        'top_k': 50,
        'max_tokens': 8192
    },
    'gemini-flash-experimental': {
        'description': 'Gemini Flash Experimental',
        'temperature': 0.7,
        'top_p': 0.8,
        'top_k': 30,
        'max_tokens': 4096
    },
    'gemini-2.0-flash-thinking-exp-01-21': {
        'description': 'Gemini 2.0 Flash Thinking Experimental',
        'temperature': 0.8,
        'top_p': 0.9,
        'top_k': 40,
        'max_tokens': 8192
    }
}

DEFAULT_MODEL = 'gemini-2.0-flash'


# 🚀 Generation Configuration
def configure_generation(model_name):
    config = MODEL_OPTIONS.get(model_name, MODEL_OPTIONS[DEFAULT_MODEL])
    return {
        "temperature": config['temperature'],
        "top_p": config['top_p'],
        "top_k": config['top_k'],
        "max_output_tokens": config['max_tokens'],
        "response_mime_type": "text/plain",
    }


# 💬 Send Message to Gemini API
def send_message(sessao, mensagem, image_data=None):
    try:
        if image_data:
            response = sessao.send_message(
                {
                    "parts": [
                        {"text": mensagem},
                        {"inline_data": {"mime_type": "image/jpeg", "data": image_data}}
                    ]
                }
            )
        else:
            response = sessao.send_message({"parts": [{"text": mensagem}]})

        return response.text.strip()
    except Exception as e:
        logging.error(f"Error sending message: {e}")
        print(f"{Fore.RED}Error sending message to Gemini API: {e}{Style.RESET_ALL}")
        return None


# Custom Widget to Handle Drag and Drop
class DropArea(QLabel):
    dropped = pyqtSignal(list)

    def __init__(self, parent=None):
        super().__init(parent)
        self.setAlignment(Qt.AlignCenter)
        self.setText("Arraste e solte imagens aqui 🖼️")
        self.setStyleSheet("""
            QLabel {
                border: 4px dashed #80CBC4;
                padding: 40px;
                font-size: 20px;
                color: #37474F;
                background-color: #ECEFF1;
                border-radius: 10px;
            }
            QLabel:hover {
                background-color: #CFD8DC;
            }
        """)
        self.setAcceptDrops(True)

    def dragEnterEvent(self, event: QDragEnterEvent):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
            self.setStyleSheet("""
                QLabel {
                    border: 4px solid #26A69A;
                    padding: 40px;
                    font-size: 20px;
                    color: #37474F;
                    background-color: #B2DFDB;
                    border-radius: 10px;
                }
            """)

    def dragLeaveEvent(self, event):
        self.setStyleSheet("""
            QLabel {
                border: 4px dashed #80CBC4;
                padding: 40px;
                font-size: 20px;
                color: #37474F;
                background-color: #ECEFF1;
                border-radius: 10px;
            }
        """)

    def dropEvent(self, event: QDropEvent):
        self.setStyleSheet("""
            QLabel {
                border: 4px dashed #80CBC4;
                padding: 40px;
                font-size: 20px;
                color: #37474F;
                background-color: #ECEFF1;
                border-radius: 10px;
            }
        """)
        files = [url.toLocalFile() for url in event.mimeData().urls()]
        self.dropped.emit(files)


# Main Window Class
class MainWindow(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("🖼️ Gemini Image Analyzer 🧠")
        self.setGeometry(100, 100, 800, 600)

        # UI elements
        self.api_key_input = QLineEdit(self)  # API Key Input Field
        self.api_key_input.setPlaceholderText("Insira sua API Key do Gemini aqui")

        self.model_selector = QComboBox(self)  # Model Selection Dropdown
        for model_name, model_data in MODEL_OPTIONS.items():
            self.model_selector.addItem(model_data['description'], model_name) # Display Description, store name

        self.drop_area = DropArea(self)
        self.image_list = QListWidget()
        self.analyze_button = QPushButton("Analisar Imagens ✨")
        self.analyze_button.clicked.connect(self.analyze_images)
        self.clear_button = QPushButton("Limpar Lista 🧹")
        self.clear_button.clicked.connect(self.clear_image_list)
        self.response_area = QTextEdit()
        self.response_area.setReadOnly(True)

        self.progress_bar = QProgressBar()
        self.progress_bar.setValue(0)

        # Button Layout
        button_layout = QHBoxLayout()
        button_layout.addWidget(self.analyze_button)
        button_layout.addWidget(self.clear_button)

        # Layout
        main_layout = QVBoxLayout()
        main_layout.addWidget(self.api_key_input)  # Add API Key Input Field
        main_layout.addWidget(self.model_selector)  # Add Model Selection Dropdown
        main_layout.addWidget(self.drop_area)
        main_layout.addWidget(self.image_list)
        main_layout.addLayout(button_layout)
        main_layout.addWidget(self.response_area)
        main_layout.addWidget(self.progress_bar)
        self.setLayout(main_layout)

        # Style (added style for API Key input)
        self.setStyleSheet("""
            QWidget {
                background-color: #F5F5F5;
                font-family: sans-serif;
                font-size: 14px;
                color: #212121;
            }
            QPushButton {
                background-color: #4CAF50;
                color: white;
                padding: 12px 24px;
                font-size: 16px;
                border: none;
                border-radius: 4px;
            }
            QPushButton:hover {
                background-color: #367c39;
            }
            QTextEdit {
                background-color: #FAFAFA;
                border: 1px solid #E0E0E0;
                font-family: monospace;
                font-size: 12px;
                color: #424242;
                padding: 5px;
            }
            QLineEdit {  /* Style for API Key Input */
                background-color: #FFFFFF;
                border: 1px solid #E0E0E0;
                padding: 10px;
                border-radius: 4px;
                margin-bottom: 10px;
            }
            QComboBox { /* Style for Model Selection Dropdown */
                background-color: #FFFFFF;
                border: 1px solid #E0E0E0;
                padding: 10px;
                border-radius: 4px;
                margin-bottom: 10px;
            }
        """)

        # Data
        self.image_paths = []
        self.api_key = None  # Initialize API Key
        self.selected_model = DEFAULT_MODEL # Initialize Selected Model

        # Signal Connection
        self.drop_area.dropped.connect(self.add_images_to_queue)
        self.model_selector.currentIndexChanged.connect(self.on_model_changed)  # Connect model change

        # Load API Key from config file on startup
        self.load_stored_api_key()
        self.initialize_gemini_session()  # Initialize Gemini after loading API Key

    def load_stored_api_key(self):
        """Loads the API key from the config file and sets it in the input field."""
        stored_key = load_api_key()
        if stored_key:
            self.api_key = stored_key
            self.api_key_input.setText(stored_key)
        else:
            print(f"{Fore.YELLOW}Nenhuma API Key encontrada no arquivo de configuração.{Style.RESET_ALL}")

    def initialize_gemini_session(self):
        """Initializes the Gemini chat session using the API key and selected model."""
        current_api_key = self.api_key_input.text()

        if not current_api_key:
            QMessageBox.warning(self, "Aviso", "Por favor, insira sua API Key do Gemini.")
            self.analyze_button.setEnabled(False)
            return

        try:
            genai.configure(api_key=current_api_key)  # Configure genai with user input API Key
            self.chat_session = genai.GenerativeModel(
                model_name=self.selected_model,
                generation_config=configure_generation(self.selected_model)
            ).start_chat(history=[])
            self.api_key = current_api_key  # Store the API key if initialization is successful
            save_api_key(current_api_key)  # Save the API Key to YAML
            self.analyze_button.setEnabled(True)  # Enable Analyze Button after successful initialization
            print(f"{Fore.GREEN}Sessão Gemini iniciada com sucesso! Usando modelo: {self.selected_model}{Style.RESET_ALL}")

        except Exception as e:
            QMessageBox.critical(self, "Erro", f"Erro ao iniciar sessão com Gemini: {e}")
            logging.error(f"Error starting chat session: {e}")
            print(f"{Fore.RED}Error starting Gemini chat session: {e}{Style.RESET_ALL}")
            self.analyze_button.setEnabled(False)

    def on_model_changed(self):
        """Handles the event when the user changes the selected model in the dropdown."""
        self.selected_model = self.model_selector.itemData(self.model_selector.currentIndex()) # Get model name from data
        print(f"{Fore.BLUE}Modelo selecionado: {self.selected_model}{Style.RESET_ALL}")
        #Reinitialize the session when the model changes
        self.initialize_gemini_session()


    # Add Images to Queue
    def add_images_to_queue(self, files):
        valid_extensions = ['.jpg', '.jpeg', '.png', '.gif']  # Added GIF
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in valid_extensions and file not in self.image_paths:
                self.image_paths.append(file)
                item = QListWidgetItem(QIcon("image.png"), os.path.basename(file))
                self.image_list.addItem(item)

    # Create Collage
    def create_collage(self, image_paths):
        if not image_paths:
            return None

        img_list = []
        max_width = 0
        total_height = 0
        try:
            for img_path in image_paths:
                img = Image.open(img_path).convert('RGB')
                img_list.append(img)
                max_width = max(max_width, img.width)
                total_height += img.height

            collage = Image.new('RGB', (max_width, total_height), (255, 255, 255))  # White background
            y_offset = 0
            for img in img_list:
                # Resize to max_width, maintaining aspect ratio
                if img.width != max_width:
                    new_height = int(img.height * (max_width / img.width))
                    img = img.resize((max_width, new_height), Image.Resampling.LANCZOS)
                collage.paste(img, (0, y_offset))
                y_offset += img.height
        except Exception as e:
            QMessageBox.critical(self, "Erro", f"Erro ao criar colagem: {e}")
            logging.error(f"Error creating collage: {e}")
            print(f"{Fore.RED}Error creating collage: {e}{Style.RESET_ALL}")
            return None

        # Save collage to bytes and encode
        img_bytes = io.BytesIO()
        collage.save(img_bytes, format='JPEG', quality=90)  # save as JPEG
        img_bytes.seek(0)
        collage_base64 = base64.b64encode(img_bytes.read()).decode('utf-8')
        return collage_base64

    # Analyze Images
    def analyze_images(self):
        if not self.image_paths:
            QMessageBox.information(self, "Info", "Arraste e solte imagens na área designada.")
            return

        # Check if API Key is set before proceeding
        if not self.api_key:
            self.initialize_gemini_session()  # Try to initialize again, in case user entered key
            if not self.api_key:  # If still no API Key, stop analysis
                QMessageBox.warning(self, "Aviso", "Por favor, insira e configure sua API Key do Gemini.")
                return

        # Create Collage
        collage_base64 = self.create_collage(self.image_paths)
        if not collage_base64:
            return

        # Generate Filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        suggested_filename = f"image_analysis_{timestamp}"

        # Create Prompt
        prompt = f"""
        Você é um analista técnico especializado em price action no mercado financeiro, incluindo criptomoedas, ações e outros ativos.
        Sua função é analisar gráficos de preços em busca de padrões ocultos e fornecer análises técnicas aprofundadas e detalhadas.
        Seu objetivo é ser altamente técnico, especialista e fornecer insights acionáveis baseados em price action.

        **Instruções:**

        1.  **Análise do Gráfico:** Examine o gráfico em busca de padrões de candles (martelo, estrela cadente, engolfo, etc.), formações gráficas (triângulos, topos e fundos duplos, ombro-cabeça-ombro, etc.) e níveis de suporte e resistência.
        2.  **Identificação de Tendências:** Determine a tendência predominante (alta, baixa ou lateral) e avalie a força dessa tendência com base na ação do preço e no volume.
        3.  **Níveis de Suporte e Resistência:** Identifique níveis de suporte e resistência significativos e explique como esses níveis podem influenciar a ação do preço futura.
        4.  **Padrões de Price Action:** Procure por padrões de price action que indiquem possíveis reversões, continuações ou consolidações da tendência.
        5.  **Análise de Volume:** Avalie o volume em relação à ação do preço. O aumento do volume em movimentos de alta pode confirmar uma tendência de alta, enquanto o aumento do volume em movimentos de baixa pode confirmar uma tendência de baixa.
        6.  **Interpretação Técnica:** Forneça uma interpretação técnica abrangente do gráfico, incluindo possíveis cenários futuros e níveis-chave a serem observados.
        7.  **Recomendações:** Com base em sua análise, forneça recomendações acionáveis, como possíveis pontos de entrada e saída, níveis de stop-loss e take-profit, e considerações de gerenciamento de risco.
        8.  **Justificativa:** Justifique suas recomendações com base em princípios de price action e em sua análise técnica do gráfico.
        9. **Adaptação:** Adapte sua análise e recomendações com base no contexto do mercado e nas características específicas do ativo em questão.
        10. **Detalhes:** Detalhe o que você vê, o que significa, por que é importante e como pode ser usado para tomar decisões de negociação informadas.
        11. **Linguagem Técnica:** Use uma linguagem técnica apropriada e explique os conceitos de price action de forma clara e concisa.
        12. **Gráfico e Análise:** Interprete tanto o gráfico quanto qualquer análise que esteja presente no gráfico (por exemplo, indicadores técnicos, linhas de tendência).
        13. **Sustentação e Refutação:** Sustente ou refute suas conclusões com base em seu entendimento do price action e da análise técnica.
        14. **Estado da Arte:** Demonstre um conhecimento profundo do price action no estado da arte, incorporando conceitos avançados e técnicas de análise.
        15. **Formato de Saída:** Sua resposta deve ser um documento Markdown completo, pronto para ser salvo em um arquivo .md. Inclua um cabeçalho principal, seções bem definidas e um rodapé.
        16. **Seja Criativo:** Use dados, crie produtos, entregue resultados, faça tabelas de informações, colete dados, seja rico em criatividade para gerar coisas relevantes com base nessas imagens
        17. **Seja divertido:** Entregue emojis e icones e responda em português do brasil sempre
        """

        # Send to Gemini and get the response
        response_text = send_message(self.chat_session, prompt, collage_base64)

        # Display Response and Save to File
        if response_text:
            self.response_area.setText(response_text)
            project_dir = self.save_response_to_md(response_text)  # Save response to .md file
            if project_dir:
                self.copy_images_to_project(project_dir)
        else:
            QMessageBox.warning(self, "Aviso", "Não foi possível obter uma resposta da IA.")
            self.response_area.setText("Erro ao obter resposta da IA.")
        self.progress_bar.setValue(100)  # set to complete

    def clear_image_list(self):
        """Clears the image list and resets the UI."""
        self.image_paths = []
        self.image_list.clear()
        self.response_area.clear()
        self.progress_bar.setValue(0)

    def create_project_directory(self):
        """Creates a unique project directory based on the current timestamp."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        project_dir = f"gemini_analysis_project_{timestamp}"
        os.makedirs(project_dir, exist_ok=True)  # exist_ok = true para não dar erro se já existir
        return project_dir

    def save_response_to_md(self, response_text):
        """Saves the Gemini API response to a Markdown file inside a project directory,
        extracting the filename from the first line."""
        project_dir = self.create_project_directory()
        try:
            # Extract the filename from the first line of the response
            filename_match = re.search(r"------(.*?)------", response_text)
            if filename_match:
                filename = filename_match.group(1).strip() + ".md"  # Add .md extension
                # Remove filename from the content
                response_content = response_text[filename_match.end():].strip()
            else:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"gemini_analysis_{timestamp}.md"
                response_content = response_text  # keep everything

            filepath = os.path.join(project_dir, filename)  # path to save MD
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(response_content)
            QMessageBox.information(self, "Sucesso", f"Análise salva em {filepath}")
            print(f"{Fore.GREEN}Análise salva em {filepath}{Style.RESET_ALL}")  # Colored console output
            logging.info(f"Análise salva em {filepath}")
            return project_dir  # Return project dir path

        except Exception as e:
            QMessageBox.critical(self, "Erro", f"Erro ao salvar arquivo: {e}")
            logging.error(f"Erro ao salvar arquivo: {e}")
            print(f"{Fore.RED}Erro ao salvar arquivo: {e}{Style.RESET_ALL}")
            return None

    def copy_images_to_project(self, project_dir):
        """Copies the input images to the project directory."""
        try:
            for image_path in self.image_paths:
                shutil.copy(image_path, project_dir)
            print(
                f"{Fore.GREEN}Imagens copiadas para o diretório do projeto: {project_dir}{Style.RESET_ALL}")
            logging.info(f"Imagens copiadas para o diretório do projeto: {project_dir}")
        except Exception as e:
            print(
                f"{Fore.RED}Erro ao copiar imagens para o diretório do projeto: {e}{Style.RESET_ALL}")
            logging.error(f"Erro ao copiar imagens para o diretório do projeto: {e}")


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec_())
