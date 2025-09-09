require 'sinatra'
require 'pathname'
require 'fileutils'
require 'json'

enable :sessions

# Configurações do Sinatra
set :bind, '0.0.0.0'
set :port, 4567

# A pasta para as imagens estáticas. Elas precisam estar em `public/images`.
# O Sinatra automaticamente serve arquivos de dentro da pasta `public`.
ROOT_DIR = Pathname.new('public')
IMAGES_DIR = ROOT_DIR.join('images')

IMAGES_DIR.mkpath unless IMAGES_DIR.exist?


# Rota principal que exibe a galeria de imagens
get '/' do
  # Pega todos os arquivos de imagem (jpg, jpeg, png, gif) no diretório de imagens.
  unless session[:images]
    all_images = Dir.glob(IMAGES_DIR.join('*.{jpg,jpeg,png,gif}'))
    untagged_images = all_images.select do |path| 
      Pathname.new(path).dirname == IMAGES_DIR
    end
    session[:history] = untagged_images
  end

  session[:history] ||= []

  current_image_path = session[:history].first

    erb :index, locals: {
      image_path: current_image_path,
      remaining: (session[:images] || []).size,
      history_available: session[:history].any?
    }
end

post '/classify' do
  image_path = params[:image_path]
  tag = params[:tag].strip.downcase

  if image_path && tag && !tag.empty? 
    source_path = Pathname.new(image_path)
    dest_dir = IMAGES_DIR.join(tag)
    dest_path = dest_dir.join(source_path.basename)

    dest_dir.mkpath unless dest_dir.exist?
    FileUtils.mv(source_path, dest_path.to_s)
    
    session[:history] << { source: image_path, destination: dest_path.to_s }

    session[:images].shift if session[:images]
  end
  
  redirect '/'
end

post '/undo' do
  if session[:history] && session[:history].any?
    last_action = session[:history].pop
    source_path = Pathname.new(last_action[:destination])
    dest_path = Pathname.new(last_action[:source])

    if source_path.exist?
      FileUtils.mv(source_path.to_s, dest_path.to_s)

      session[:images].unshift(source_path.to_s) if session[:images]
    end
  end
  redirect '/'
end

post 'skip' do
  session[:images].rotate!
  redirect '/'

end

__END__

@@index
<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Galeria de Imagens</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #121212;
      color: #e0e0e0;
      margin: 0;
      padding: 20px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
    }
    .container {
      max-width: 800px;
      margin: auto;
      text-align: center;
      background-color: #1e1e1e;
      padding: 30px;
      border-radius: 12px;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5);
    }
    h1 {
      color: #bb86fc;
      margin-bottom: 20px;
    }
    .image-display {
      width: 100%;
      height: 400px;
      background-color: #2c2c2c;
      border-radius: 8px;
      margin-bottom: 20px;
      overflow: hidden;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    .image-display img {
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
    }
    .controls {
      display: flex;
      flex-direction: column;
      gap: 15px;
    }
    .tag-form {
      display: flex;
      gap: 10px;
      width: 100%;
    }
    .tag-form input[type="text"] {
      flex-grow: 1;
      padding: 10px;
      border-radius: 8px;
      border: 1px solid #333;
      background-color: #2c2c2c;
      color: #e0e0e0;
      outline: none;
    }
    .tag-form button {
      background-color: #03dac6;
      color: #121212;
    }
    .action-buttons {
      display: flex;
      justify-content: space-between;
      gap: 10px;
    }
    .action-buttons button {
      flex-grow: 1;
    }
    button {
      padding: 12px 20px;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      font-weight: bold;
      transition: background-color 0.2s, transform 0.2s;
    }
    .skip-button {
      background-color: #cf6679;
      color: #121212;
    }
    .undo-button {
      background-color: #bb86fc;
      color: #121212;
    }
    button:hover {
      transform: translateY(-2px);
    }
    button:active {
      transform: translateY(0);
    }
    .no-images {
      font-size: 1.5em;
      color: #cf6679;
      margin-top: 50px;
    }
    .count {
      margin-top: 10px;
      color: #999;
    }
  </style>
</head>

<body>
  <div class="container">
    <h1>Minhas Imagens</h1>
    <% if image_path %>
      <div class="image-display">
        <img src="/<%= Pathname.new(image_path).relative_path_from(ROOT_DIR) %>" alt="Imagem para classificar">
      </div>
      <div class="controls">
        <form class="tag-form" action="/classify" method="post">
          <input type="hidden" name="image_path" value="<%= image_path %>">
          <input type="text" name="tag" placeholder="Digite uma tag (ex: paisagem, familia, férias)" required>
          <button type="submit">Classificar e Mover</button>
        </form>
        <div class="action-buttons">
          <form action="/skip" method="post">
            <button class="skip-button" type="submit">Pular</button>
          </form>
          <form action="/undo" method="post">
            <button class="undo-button" type="submit" <%= 'disabled' if !history_available %>>Desfazer</button>
          </form>
        </div>
      </div>
      <p class="count">Imagens restantes na fila: <%= remaining %></p>
    <% else %>
      <p class="no-images">Todas as imagens foram classificadas!</p>
      <p class="count">Você pode adicionar mais imagens na pasta `public/images` para recomeçar.</p>
    <% end %>
  </div>
</body>
</html>
