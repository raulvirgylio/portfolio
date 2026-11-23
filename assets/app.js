/* Raulzito — portfólio. Lê data/videos.json e data/perfil.json. */
const PAGE = 12;
let videos = [], perfil = {}, filtro = "Todos", mostrando = PAGE;

const $ = (s) => document.querySelector(s);
const esc = (s) => String(s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
// IDs de YouTube/Drive entram dentro de URL: deixar só caracteres válidos de ID.
const escId = (s) => String(s).replace(/[^A-Za-z0-9_-]/g, "");

function categorias() {
  const c = [...new Set(videos.map(v => v.categoria).filter(Boolean))];
  return ["Todos", ...c.sort((a, b) =>
    videos.filter(v => v.categoria === b).length - videos.filter(v => v.categoria === a).length)];
}

function pintarFiltros() {
  $("#filters").innerHTML = categorias().map(c =>
    `<button data-c="${esc(c)}" aria-pressed="${c === filtro}">${esc(c)}</button>`).join("");
  $("#filters").querySelectorAll("button").forEach(b => b.addEventListener("click", () => {
    filtro = b.dataset.c; mostrando = PAGE; pintarFiltros(); pintarGrade();
  }));
}

function listaFiltrada() {
  const l = filtro === "Todos" ? videos : videos.filter(v => v.categoria === filtro);
  return [...l].sort((a, b) => (b.destaque === true) - (a.destaque === true) || (b.views || 0) - (a.views || 0));
}

function thumbDe(v) {
  if (v.capa) return encodeURI(String(v.capa));   // capa própria: assets/capas/arquivo.jpg
  return v.fonte === "drive"
    ? `https://drive.google.com/thumbnail?id=${escId(v.id)}&sz=w640`
    : `https://i.ytimg.com/vi/${escId(v.id)}/hqdefault.jpg`;
}
function embedDe(v) {
  return v.fonte === "drive"
    ? `https://drive.google.com/file/d/${escId(v.id)}/preview`
    : `https://www.youtube-nocookie.com/embed/${escId(v.id)}?autoplay=1&rel=0`;
}

function pintarGrade() {
  const l = listaFiltrada(), vis = l.slice(0, mostrando);
  if (!l.length) {
    $("#grid").innerHTML = '<p class="vazio-aviso">Nenhum vídeo em data/videos.json ainda — faça a triagem em triagem.html e substitua o arquivo.</p>';
    $("#loadmore").hidden = true; return;
  }
  $("#grid").innerHTML = vis.map(v => `
    <button class="card${v.destaque ? " destaque" : ""}" data-tit="${esc(v.titulo)}" data-emb="${esc(embedDe(v))}">
      <span class="canto c1"></span><span class="canto c2"></span>
      <span class="canto c3"></span><span class="canto c4"></span>
      <span class="thumb">
        <img loading="lazy" src="${esc(thumbDe(v))}" alt="" referrerpolicy="no-referrer">
        <span class="play"><span><i>&#9654;</i></span></span>
        ${v.dur_fmt ? `<span class="dur">${esc(v.dur_fmt)}</span>` : ""}
      </span>
      <h3>${esc(v.titulo)}</h3>
      <span class="tags">
        ${v.categoria ? `<span class="cat">${esc(v.categoria)}</span>` : ""}
        ${(v.papeis || []).map(p => `<span class="papel${p === "vivo" ? " vivo" : ""}">${esc(rotulo(p))}</span>`).join("")}
      </span>
    </button>`).join("");
  $("#loadmore").hidden = mostrando >= l.length;
  $("#grid").querySelectorAll(".card").forEach(c =>
    c.addEventListener("click", () => abrir(c.dataset.emb, c.dataset.tit)));
}

function rotulo(p) {
  return { editei: "Edição", gravei: "Câmera", vivo: "Ao vivo", partic: "Participação" }[p] || p;
}

function abrir(embed, tit) {
  $("#iframe").src = embed;
  $("#player-tit").textContent = tit;
  $("#player").showModal();
}
function fechar() { $("#player").close(); $("#iframe").src = ""; }

function pintarContato() {
  const wa = (perfil.whatsapp || "").replace(/\D/g, "");
  const map = {
    "#lk-wa": wa ? { href: `https://wa.me/${wa}`, txt: "WhatsApp " + perfil.whatsapp } : null,
    "#lk-ig": perfil.instagram ? { href: `https://instagram.com/${perfil.instagram.replace("@", "")}`, txt: perfil.instagram } : null,
    "#lk-mail": perfil.email ? { href: `mailto:${perfil.email}`, txt: perfil.email } : null,
  };
  for (const [sel, dados] of Object.entries(map)) {
    const a = $(sel); if (!a) continue;
    if (dados) { a.href = dados.href; a.textContent = dados.txt; a.target = "_blank"; a.rel = "noopener"; }
    else { a.textContent = a.dataset.ph + " — a preencher"; a.dataset.vazio = "1"; a.removeAttribute("href"); }
  }
}

async function carregar() {
  const [v, x, p] = await Promise.all([
    fetch("data/videos.json").then(r => r.ok ? r.json() : []).catch(() => []),
    fetch("data/extras.json").then(r => r.ok ? r.json() : []).catch(() => []),
    fetch("data/perfil.json").then(r => r.ok ? r.json() : {}).catch(() => ({})),
  ]);
  // extras.json = peças fora do canal (Drive etc). Fica separado para a triagem não sobrescrever.
  const vistos = new Set();
  videos = [...(Array.isArray(x) ? x : []), ...(Array.isArray(v) ? v : [])]
    .filter(it => it && it.id && !vistos.has(it.id) && vistos.add(it.id));
  perfil = p || {};
  // foto do "sobre mim": caminho vem do perfil.json, então basta trocar o arquivo
  const img = $("#foto-sobre");
  if (img && perfil.foto) img.src = perfil.foto;
  $("#f-total").textContent = videos.length || "—";
  $("#f-cats").textContent = Math.max(categorias().length - 1, 0) || "—";
  pintarFiltros(); pintarGrade(); pintarContato();
}

/* Contador de visitas estilo web 1.0.
   É LOCAL: conta quantas vezes ESTE navegador abriu a página, não o tráfego real.
   Não há número inventado de base. Para um contador de verdade, use um serviço
   externo (GoatCounter, CounterAPI) — veja o README. */
function pintarContador() {
  const el = $("#contador"); if (!el) return;
  const k = "raulzito_visitas";
  const n = (parseInt(localStorage.getItem(k) || "0", 10) || 0) + 1;
  localStorage.setItem(k, n);
  String(n).padStart(6, "0").split("")
    .forEach(d => { const b = document.createElement("b"); b.textContent = d; el.appendChild(b); });
  el.setAttribute("aria-label", `Suas visitas a esta página: ${n}`);
  el.setAttribute("title", "Suas visitas a esta página (contagem local do seu navegador)");
}

$("#loadmore").addEventListener("click", () => { mostrando += PAGE; pintarGrade(); });
$("#player .fechar").addEventListener("click", fechar);
$("#player").addEventListener("close", () => { $("#iframe").src = ""; });
$("#player").addEventListener("click", e => { if (e.target.id === "player") fechar(); });
$("#ano").textContent = new Date().getFullYear();
pintarContador();
carregar();
