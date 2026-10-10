// BYU Trip Share - "Request a Seat" vertical slice
// Flow: button click -> request_seat() in Supabase -> row inserted into seat_requests
//       -> saved row returned -> button updates. On refresh, status is re-read from the database.

const DEFAULT_RIDER_ID = 3;            // Tanner, a sample rider with an open trip to request
const RIDER_STORAGE_KEY = "tripshare.riderId";

const tripsEl = document.getElementById("trips");
const riderSelect = document.getElementById("riderSelect");
const bannerEl = document.getElementById("banner");
const toastEl = document.getElementById("toast");

let db = null;
let currentRiderId = DEFAULT_RIDER_ID;

// ---------- startup ----------
init();

async function init() {
  const cfg = window.APP_CONFIG;
  if (!cfg || !cfg.SUPABASE_URL || cfg.SUPABASE_URL.includes("your-project-id")) {
    showBanner('Missing Supabase keys. Copy <code>app/config.example.js</code> to <code>app/config.js</code> and paste in your project URL and anon key.');
    tripsEl.innerHTML = "";
    return;
  }
  if (!window.supabase) {
    showBanner("Couldn't load the Supabase library. Check your internet connection and refresh.");
    tripsEl.innerHTML = "";
    return;
  }

  db = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);

  try {
    const saved = Number(localStorage.getItem(RIDER_STORAGE_KEY));
    if (saved) currentRiderId = saved;
  } catch (_) { /* storage unavailable: fall back to default rider */ }

  await loadRiders();
  await loadTrips();

  riderSelect.addEventListener("change", async () => {
    currentRiderId = Number(riderSelect.value);
    try { localStorage.setItem(RIDER_STORAGE_KEY, String(currentRiderId)); } catch (_) {}
    await loadTrips();
  });
}

// ---------- data loading (reads from the database) ----------
async function loadRiders() {
  const { data, error } = await db.rpc("get_demo_users");
  if (error) {
    showBanner("Couldn't load users: " + escapeHtml(error.message));
    return;
  }
  if (!data.some(u => u.user_id === currentRiderId)) currentRiderId = data[0]?.user_id;
  riderSelect.innerHTML = data
    .map(u => `<option value="${u.user_id}">${escapeHtml(u.first_name)} ${escapeHtml(u.last_name)} (@${escapeHtml(u.username)})</option>`)
    .join("");
  riderSelect.value = String(currentRiderId);
}

async function loadTrips() {
  tripsEl.innerHTML = '<p class="loading">Loading trips…</p>';
  const { data, error } = await db.rpc("get_trip_listings", { p_rider_id: currentRiderId });
  if (error) {
    tripsEl.innerHTML = "";
    showBanner("Couldn't load trips: " + escapeHtml(error.message));
    return;
  }
  hideBanner();
  if (!data.length) {
    tripsEl.innerHTML = '<p class="loading">No upcoming trips yet.</p>';
    return;
  }
  tripsEl.innerHTML = data.map(renderTrip).join("");
  tripsEl.querySelectorAll("[data-request]").forEach(btn =>
    btn.addEventListener("click", () => requestSeat(Number(btn.dataset.request)))
  );
}

// ---------- THE VERTICAL SLICE ----------
async function requestSeat(tripId) {
  const card = tripsEl.querySelector(`[data-trip="${tripId}"]`);
  const actionEl = card.querySelector(".action");
  const btn = actionEl.querySelector("button");

  // Block double clicks and show progress
  btn.disabled = true;
  btn.className = "btn btn-sending";
  btn.textContent = "Sending request…";

  // (1) Send the request to the backend
  const { data, error } = await db.rpc("request_seat", {
    p_trip_id: tripId,
    p_rider_id: currentRiderId
  });

  if (error) {
    btn.disabled = false;
    btn.className = "btn btn-primary";
    btn.textContent = "Request a Seat";
    actionEl.querySelector(".card-error")?.remove();
    actionEl.insertAdjacentHTML("beforeend", `<p class="card-error">${escapeHtml(error.message)}</p>`);
    return;
  }

  // (2) The database inserted the row. (3) It came back to us here:
  const saved = data[0];

  // (4) Display the saved value from the database in the UI
  actionEl.innerHTML =
    buttonFor(saved.request_status, {}) +
    `<p class="saved-at">Saved to database · request #${saved.request_id} · ${formatTime(saved.requested_at)}</p>`;
  showToast("Seat requested. Refresh the page and it will still be there.");
}

// ---------- rendering ----------
function renderTrip(t) {
  const seatsText = t.seats_available > 0
    ? `<span class="seats"><strong>${t.seats_available}</strong> of ${t.total_seats} seats left</span>`
    : `<span class="seats none">No seats left</span>`;

  return `
  <article class="trip" data-trip="${t.trip_id}">
    <img src="${escapeAttr(t.photo_url || "")}" alt="${escapeAttr(t.destination_name)}" loading="lazy"
         onerror="this.removeAttribute('src'); this.alt='';">
    <div class="trip-body">
      <span class="chip">${escapeHtml(t.category)}</span>
      <div class="trip-title">
        <h3>${escapeHtml(t.destination_name)}</h3>
        <span class="price">$${Number(t.price_per_seat).toFixed(2)} <small>/ seat</small></span>
      </div>
      <ul class="meta">
        <li>Driver: <strong>${escapeHtml(t.driver_first_name)}</strong></li>
        <li>Leaves: <strong>${formatTime(t.departure_time)}</strong></li>
        <li>From: ${escapeHtml(t.departure_location)}</li>
      </ul>
      ${seatsText}
      ${t.trip_notes ? `<p class="notes">"${escapeHtml(t.trip_notes)}"</p>` : ""}
      <div class="action">${buttonFor(t.my_request_status, t)}</div>
    </div>
  </article>`;
}

function buttonFor(status, trip) {
  if (status === "pending")  return `<button class="btn btn-pending" disabled>Request Pending</button>`;
  if (status === "accepted") return `<button class="btn btn-accepted" disabled>Seat Confirmed ✓</button>`;
  if (status === "denied")   return `<button class="btn btn-denied" disabled>Request Denied</button>`;
  if (status === "cancelled") return `<button class="btn btn-denied" disabled>Request Cancelled</button>`;
  if (trip.driver_id === currentRiderId) return `<button class="btn btn-driver" disabled>You're driving</button>`;
  if (trip.trip_status !== "open" || trip.seats_available < 1)
    return `<button class="btn btn-full" disabled>Trip Full</button>`;
  return `<button class="btn btn-primary" data-request="${trip.trip_id}">Request a Seat</button>`;
}

// ---------- helpers ----------
function formatTime(iso) {
  return new Date(iso).toLocaleString("en-US", {
    weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit",
    timeZone: "America/Denver"
  });
}

function showBanner(html) { bannerEl.innerHTML = html; bannerEl.hidden = false; }
function hideBanner() { bannerEl.hidden = true; }

let toastTimer;
function showToast(msg) {
  toastEl.textContent = msg;
  toastEl.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => (toastEl.hidden = true), 4000);
}

function escapeHtml(s) {
  return String(s ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
function escapeAttr(s) { return escapeHtml(s); }
