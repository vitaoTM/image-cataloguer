# Classificador de Imagens

Este é um aplicativo web simples para organizar e classificar imagens em pastas. Ele foi desenvolvido com Ruby e o framework web Sinatra.

## Funcionalidades
- Visualização de Imagem: Exibe uma imagem por vez para facilitar a classificação.

- Classificação por Tags: Mova a imagem atual para uma pasta com o nome de uma tag que você definir.

- Botões de Tags Recentes: As últimas tags utilizadas são salvas como botões de acesso rápido.

- Pular Imagem: Permite pular uma imagem sem classificá-la, enviando-a para o final da fila.

- Desfazer (Undo): Desfaz a última ação de classificação, movendo a imagem de volta para a pasta original.

- Seleção de Pasta: Permite que você escolha qualquer pasta no seu sistema de arquivos para classificar as imagens.

## Pré-requisitos
Certifique-se de que você tem o Ruby instalado. Para verificar, abra o terminal e execute:

` ruby -v `

Você também precisará instalar as gems do Sinatra e do Puma (o servidor web que rodará a aplicação):

```
gem install sinatra
gem install puma
```

## Como Usar

1. Clone o Repositório ou Crie os Arquivos: Se você ainda não tem os arquivos, crie a seguinte estrutura de pastas:

```
.
├── app.rb
├── public/
    ├── images/
│   └── style.css
└── views/
    ├── index.erb
    └── select_folder.erb
```

Copie o código de cada arquivo ( app.rb, style.css, index.erb, e select_folder.erb) para seus respectivos lugares.

2. Adicione suas Imagens: Coloque as imagens que você deseja classificar em uma pasta na pasta public/images da aplicação.

3. Execute o Aplicativo: Abra o terminal, navegue até o diretório raiz do projeto e execute o comando:

`ruby app.rb`

4. Acesse no Navegador: Abra seu navegador e acesse http://localhost:4567.

5. Comece a Classificar: Na primeira tela, insira o caminho completo da pasta de imagens (por exemplo, /home/seu-usuario/Fotos) e clique em "Carregar Imagens". A aplicação irá exibir a primeira imagem para você começar a classificar.

