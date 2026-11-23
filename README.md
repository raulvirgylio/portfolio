# Portfólio Raulzito — Videomaker

Site estático (HTML/CSS/JS puro, sem build) que mostra os trabalhos via embed do YouTube e do Drive.

## Estética

**Art Déco + internet antiga.** Molduras escalonadas de latão, raios de sol atrás do título,
losangos, fita vermelha corrida de "em cartaz", contador de visitas em fósforo verde e granulado
de película por cima de tudo.

Grade de cor: âmbar de vela sobre sombra verde-petróleo (*Harry Potter 1*), latão envelhecido,
oxblood (*Django*), osso empoeirado (*No Country for Old Men*), fósforo verde só pra sinalizar
ao vivo (*Matrix*). As miniaturas levam essa grade por CSS (`sepia + hue-rotate`), então material
de origens diferentes fica no mesmo tom.

Tipografia **de escritório**, não caligráfica: **Jost** nos títulos e etiquetas (geométrica dos anos
30, linhagem Futura — sóbria como fonte de documento, mas com a geometria certa pro déco),
**IBM Plex Sans** no texto corrido e **IBM Plex Mono** nos números e durações.

A versão minimalista anterior ficou guardada em `index-v1-minimal.html` +
`assets/style-v1-minimal.css`, caso você queira comparar.

## Segurança

Site **100% estático**: HTML, CSS e um arquivo JS. Não existe servidor, banco de dados, login,
formulário que envie dados, nem área administrativa. Não há o que invadir do lado do servidor —
o GitHub Pages só devolve arquivos, sempre por HTTPS.

O que foi feito e checado:

- **Escape de HTML** em tudo que vem de fora (títulos do YouTube). Sem isso, um título com
  `<img onerror=...>` executaria script na página. Testado com um título hostil de propósito:
  não executa, aparece como texto.
- **IDs sanitizados** antes de entrar em URL de embed (só `A-Za-z0-9_-`).
- **Zero segredos no repositório** — não há chave de API, token ou senha, porque nada aqui
  autentica em lugar nenhum.
- **Zero dependências de código de terceiros**: sem npm, sem jQuery, sem framework, sem CDN de
  script. Nada de cadeia de supply chain pra ser comprometida.
- Player do YouTube via **youtube-nocookie.com** (não grava cookie de rastreio antes do play).

O que é consciente e você precisa saber:

| Ponto | Situação |
|---|---|
| **Telefone e e-mail públicos** | Ficam visíveis no site e no repositório — é o objetivo, mas atrai spam. Se encher o saco, troque por um formulário (Formspree tem plano grátis). |
| **Vídeos do Drive** | Pra tocarem no site precisam estar como "qualquer pessoa com o link". Quem abrir o site consegue baixar o arquivo. Se for material sensível, suba no YouTube como "não listado". |
| **Google Fonts** | Carrega de servidor do Google, então o IP de quem visita passa por lá. Dá pra baixar as fontes e servir local, se preferir. |
| **Contador de visitas** | É **local** — conta só as suas aberturas naquele navegador, não o tráfego real. É enfeite retrô, não métrica. Para número real: GoatCounter ou CounterAPI (grátis). |
| **`triagem.html`** | Se for publicada, qualquer um vê o catálogo dos 576 vídeos. Suas marcações não vazam (ficam no seu navegador), mas apague o arquivo antes do push se não quiser ela no ar. |

## Como ver no PC

O site lê arquivos JSON, então **não funciona clicando duas vezes no index.html** — precisa de um
servidor local. No terminal, dentro desta pasta:

```
python -m http.server 8777
```

Depois abra no navegador:

- Site: <http://localhost:8777/index.html>
- Triagem: <http://localhost:8777/triagem.html>

## Fluxo de trabalho

1. **Triagem** — abra `triagem.html`. Estão lá os 412 vídeos do canal da TV Conexões.
   Em cada um marque seu papel:

   | Botão | Significa |
   |---|---|
   | Editei | montagem / finalização |
   | Gravei | câmera / captação |
   | Ao vivo | transmissão ao vivo |
   | Particip. | apareço ou fiz parte da equipe |
   | ★ | destaque — vai pro topo do site com moldura |
   | Não é meu | descarta, some do portfólio |

   Pode marcar mais de um papel no mesmo vídeo. Salva sozinho no navegador (localStorage),
   dá pra fechar e continuar depois. Use o filtro **Pendentes** pra não se perder.

2. **Exportar** — clique em **Baixar videos.json** e substitua o arquivo `data/videos.json`
   por esse download. Pronto, o site passa a mostrar só o que você marcou.

3. **Seus dados** — já preenchidos em `data/perfil.json` (WhatsApp, Instagram, e-mail).
   Pra trocar, edite o arquivo; o rodapé monta os links sozinho.

4. **Sua foto** — jeito rápido, com o corte já pronto:

   ```
   bash scripts/colocar-foto.sh "E:/Imagens/minha-foto.jpg"
   ```

   Corta pelo centro em 4:5, redimensiona pra 900×1125 e salva em `assets/raulzito.jpg`.
   Se preferir enquadrar à mão, é só salvar seu arquivo com esse nome e caminho.
   Pra usar outro nome, troque o campo `"foto"` do `perfil.json`.
   Sem foto, aparece um placeholder tracejado no lugar.

5. **Capa própria de qualquer peça** — as miniaturas do Google Drive saem ruins (borradas ou pretas).
   Exporte um frame bom, salve em `assets/capas/nome.jpg` e adicione o campo `capa` na entrada:
   `"capa": "assets/capas/zumbi.jpg"`. Vale pra YouTube também, quando a thumb oficial não presta.

## Estado atual dos dados

`data/videos.json` — **13 peças confirmadas por você** (os 8 Conecta Voz ao vivo de Itaberaba a
Salvador, o Conecta Voz Final, o Docudrama Caminhos da Liberdade, o Rei do Umbu Gigante,
Glauber Vive e o Conexão Rural Roça do Povo). A triagem **sobrescreve este arquivo** — é o esperado.

`data/extras.json` — **2 peças que não estão no canal** (ZUMBI e Chão Batido, Sonho Erguido:
Rastapé de Macuco, hospedadas no Google Drive). Fica em arquivo separado de propósito: a triagem
só conhece vídeos do YouTube e apagaria essas entradas. **Adicione aqui tudo que não for do canal.**

Formato de uma entrada do `extras.json`:

```json
{
 "id": "ID_DO_ARQUIVO_NO_DRIVE",
 "fonte": "drive",
 "titulo": "Nome da peça",
 "categoria": "Documentário",
 "dur_fmt": "43:20",
 "views": 0,
 "papeis": ["gravei", "editei"],
 "destaque": true
}
```

> Vídeo no Drive só toca no site se o compartilhamento estiver em
> **"Qualquer pessoa com o link"**. Se estiver restrito, o player abre em branco.

`data/catalogo.json` — **576 vídeos** do canal (412 da aba Vídeos + 164 transmissões ao vivo),
usados só pela triagem. As marcações já confirmadas vêm pré-carregadas na primeira abertura.

## Publicar no GitHub Pages

```
git init
git add .
git commit -m "portfolio raulzito"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/portfolio.git
git push -u origin main
```

No GitHub: **Settings → Pages → Source: Deploy from a branch → main / (root) → Save**.
Em ~1 minuto o site fica em `https://SEU-USUARIO.github.io/portfolio/`.

O arquivo `.nojekyll` já está aqui pra evitar que o Jekyll atrapalhe.
A `triagem.html` também vai junto — se não quiser ela pública, apague antes de publicar.

## Atualizar o catálogo quando a TV publicar vídeos novos

```
yt-dlp --flat-playlist --extractor-args "youtube:lang=pt" \
  --print "%(id)s|%(title)s|%(duration)s|%(view_count)s" \
  "https://www.youtube.com/@TVCONEXOESAESTACAODOSABER/videos"
```

Na triagem, o botão **Importar backup** aceita um `videos.json` já marcado — então dá pra
recarregar o catálogo novo sem perder as marcações antigas.
