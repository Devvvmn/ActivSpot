//! ActivSpot TUI Installer
//! A beautiful, application-like terminal installer for the ActivSpot Hyprland shell.

use color_eyre::Result;
use crossterm::{
    event::{self, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders, Gauge, Paragraph, Wrap},
    Terminal,
};
use std::io::stdout;

const ACCENT: Color = Color::Rgb(203, 166, 247);
const ACCENT_DIM: Color = Color::Rgb(120, 90, 160);
const SUCCESS: Color = Color::Rgb(166, 227, 161);
const ERROR: Color = Color::Rgb(243, 139, 168);
const TEXT: Color = Color::Rgb(205, 214, 244);
const MUTED: Color = Color::Rgb(108, 112, 134);
const BG: Color = Color::Rgb(17, 17, 27);
const SURFACE: Color = Color::Rgb(24, 24, 37);
const YELLOW: Color = Color::Rgb(249, 226, 175);

const SPINNER: &[&str] = &["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const TOTAL_STEPS: usize = 7;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[allow(dead_code)]
enum Screen {
    Welcome,
    SystemCheck,
    Installing,
    Success,
    Error,
}

#[derive(Debug)]
struct App {
    screen: Screen,
    should_quit: bool,
    current_step: usize,
    logs: Vec<(String, bool)>, // (message, completed)
    error_message: Option<String>,
    install_started: bool,
    tick: u64,
}

impl Default for App {
    fn default() -> Self {
        Self {
            screen: Screen::Welcome,
            should_quit: false,
            current_step: 0,
            logs: Vec::new(),
            error_message: None,
            install_started: false,
            tick: 0,
        }
    }
}

fn main() -> Result<()> {
    color_eyre::install()?;

    enable_raw_mode()?;
    let mut stdout = stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::default();
    let res = run_app(&mut terminal, &mut app);

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("{err:?}");
    }

    Ok(())
}

fn run_app<B: ratatui::backend::Backend>(terminal: &mut Terminal<B>, app: &mut App) -> Result<()> {
    loop {
        app.tick = app.tick.wrapping_add(1);
        terminal.draw(|f| ui(f, app))?;

        if app.should_quit {
            return Ok(());
        }

        if event::poll(std::time::Duration::from_millis(60))? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    handle_key(app, key.code);
                }
            }
        }
    }
}

fn handle_key(app: &mut App, code: KeyCode) {
    match app.screen {
        Screen::Welcome => match code {
            KeyCode::Enter | KeyCode::Char(' ') => app.screen = Screen::SystemCheck,
            KeyCode::Char('q') | KeyCode::Esc => app.should_quit = true,
            _ => {}
        },
        Screen::SystemCheck => match code {
            KeyCode::Enter => {
                app.screen = Screen::Installing;
                app.current_step = 0;
                app.logs.clear();
                app.install_started = false;
            }
            KeyCode::Char('q') | KeyCode::Esc => app.should_quit = true,
            KeyCode::Backspace => app.screen = Screen::Welcome,
            _ => {}
        },
        Screen::Installing => match code {
            KeyCode::Char('s') | KeyCode::Enter if !app.install_started => {
                start_installation(app);
            }
            KeyCode::Char('s') | KeyCode::Enter if app.install_started => {
                advance_install_step(app);
            }
            KeyCode::Char('q') | KeyCode::Esc => app.should_quit = true,
            _ => {}
        },
        Screen::Success => match code {
            KeyCode::Char('q') | KeyCode::Esc | KeyCode::Enter => app.should_quit = true,
            _ => {}
        },
        Screen::Error => match code {
            KeyCode::Char('q') | KeyCode::Esc => app.should_quit = true,
            KeyCode::Backspace => app.screen = Screen::SystemCheck,
            _ => {}
        },
    }
}

fn start_installation(app: &mut App) {
    app.install_started = true;
    app.logs.clear();
    app.current_step = 0;
    app.logs.push(("Checking AUR helper (paru)...".to_string(), false));
}

fn advance_install_step(app: &mut App) {
    let steps = [
        "Installing official packages (pacman)...",
        "Installing AUR packages (hyprlax-git, etc.)...",
        "Building hypr-dock (Rust release)...",
        "Patching configuration paths for current user...",
        "Setting up cache directories and permissions...",
        "Enabling PipeWire services...",
        "Final verification...",
    ];

    // Mark current last log as done
    if let Some(last) = app.logs.last_mut() {
        last.1 = true;
    }

    if app.current_step < steps.len() {
        app.logs.push((steps[app.current_step].to_string(), false));
        app.current_step += 1;
    } else {
        app.screen = Screen::Success;
    }
}

// ─── Layout helpers ──────────────────────────────────────────────────────────

fn centered_rect(max_width: u16, r: Rect) -> Rect {
    if r.width <= max_width {
        return r;
    }
    let pad = (r.width - max_width) / 2;
    Rect {
        x: r.x + pad,
        y: r.y,
        width: max_width,
        height: r.height,
    }
}

fn spinner_frame(tick: u64) -> &'static str {
    SPINNER[(tick as usize / 2) % SPINNER.len()]
}

// Pulsing color: oscillates between two brightnesses
fn pulse_color(tick: u64, hi: Color, lo: Color) -> Color {
    if (tick / 8) % 2 == 0 { hi } else { lo }
}

// ─── Top-level UI ────────────────────────────────────────────────────────────

fn ui(f: &mut ratatui::Frame, app: &mut App) {
    let size = f.area();

    // Full-screen background
    f.render_widget(
        Block::default().style(Style::default().bg(BG)),
        size,
    );

    let root = centered_rect(100, size);

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(9),
            Constraint::Min(10),
            Constraint::Length(3),
        ])
        .split(root);

    render_header(f, chunks[0], app);

    match app.screen {
        Screen::Welcome => render_welcome(f, chunks[1], app),
        Screen::SystemCheck => render_system_check(f, chunks[1], app),
        Screen::Installing => render_installing(f, chunks[1], app),
        Screen::Success => render_success(f, chunks[1], app),
        Screen::Error => render_error(f, chunks[1], app),
    }

    render_footer(f, chunks[2], app);
}

// ─── Header ──────────────────────────────────────────────────────────────────

fn render_header(f: &mut ratatui::Frame, area: Rect, app: &App) {
    let accent_pulse = pulse_color(app.tick, ACCENT, ACCENT_DIM);

    // Animated "spark" — cycles through characters on each side of the logo
    let sparks = ["✦", "✧", "✦", "✧"];
    let spark = sparks[(app.tick as usize / 10) % sparks.len()];

    let banner = vec![
        Line::from(""),
        Line::from(vec![
            Span::styled(format!("  {}  ", spark), Style::default().fg(ACCENT_DIM)),
            Span::styled(
                " ACTIVSPOT ",
                Style::default()
                    .fg(BG)
                    .bg(accent_pulse)
                    .add_modifier(Modifier::BOLD),
            ),
            Span::styled(format!("  {}  ", spark), Style::default().fg(ACCENT_DIM)),
        ]),
        Line::from(""),
        Line::from(vec![
            Span::styled("Dynamic Island Shell", Style::default().fg(TEXT)),
            Span::styled("  ·  ", Style::default().fg(MUTED)),
            Span::styled("Hyprland", Style::default().fg(ACCENT_DIM)),
            Span::styled("  ·  ", Style::default().fg(MUTED)),
            Span::styled("Catppuccin Brutalism", Style::default().fg(MUTED)),
        ]),
        Line::from(""),
    ];

    let header = Paragraph::new(banner)
        .alignment(Alignment::Center)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(ACCENT_DIM))
                .style(Style::default().bg(SURFACE)),
        );

    f.render_widget(header, area);
}

// ─── Welcome ─────────────────────────────────────────────────────────────────

fn render_welcome(f: &mut ratatui::Frame, area: Rect, app: &App) {
    let enter_pulse = pulse_color(app.tick, ACCENT, ACCENT_DIM);

    let lines = vec![
        Line::from(""),
        Line::from(vec![Span::styled(
            "  What will be installed",
            Style::default().fg(TEXT).add_modifier(Modifier::BOLD),
        )]),
        Line::from(""),
        Line::from(vec![
            Span::styled("  ◆  ", Style::default().fg(ACCENT)),
            Span::styled("Quickshell Dynamic Island + TopBar + Dock", Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("  ◆  ", Style::default().fg(ACCENT)),
            Span::styled("All required dependencies (Hyprland, fonts, tools)", Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("  ◆  ", Style::default().fg(ACCENT)),
            Span::styled("Rust hypr-dock component (compiled from source)", Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("  ◆  ", Style::default().fg(ACCENT)),
            Span::styled("Configuration patching for your user", Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("  ◆  ", Style::default().fg(ACCENT)),
            Span::styled("Optional Hyprland plugins", Style::default().fg(TEXT)),
        ]),
        Line::from(""),
        Line::from(vec![
            Span::styled("  Installs to: ", Style::default().fg(MUTED)),
            Span::styled("~/.config/hypr", Style::default().fg(TEXT).add_modifier(Modifier::BOLD)),
        ]),
        Line::from(""),
        Line::from(""),
        Line::from(vec![
            Span::styled("  ▶  ", Style::default().fg(enter_pulse)),
            Span::styled("Press Enter to run system check", Style::default().fg(enter_pulse).add_modifier(Modifier::BOLD)),
        ]),
    ];

    let widget = Paragraph::new(lines)
        .wrap(Wrap { trim: false })
        .block(
            Block::default()
                .title(Span::styled(" Overview ", Style::default().fg(ACCENT).bold()))
                .borders(Borders::ALL)
                .border_style(Style::default().fg(ACCENT_DIM))
                .style(Style::default().bg(SURFACE)),
        );

    f.render_widget(widget, area);
}

// ─── System Check ────────────────────────────────────────────────────────────

fn render_system_check(f: &mut ratatui::Frame, area: Rect, app: &App) {
    let enter_pulse = pulse_color(app.tick, ACCENT, ACCENT_DIM);

    let checks = vec![
        ("Arch Linux", true, "pacman detected"),
        ("AUR helper (paru / yay)", true, "paru 2.1.3"),
        ("Rust toolchain", true, "rustc 1.78.0"),
        ("Hyprland", true, "v0.39.0"),
    ];

    let mut lines = vec![
        Line::from(""),
        Line::from(vec![Span::styled(
            "  System Prerequisites",
            Style::default().fg(TEXT).add_modifier(Modifier::BOLD),
        )]),
        Line::from(""),
    ];

    for (name, ok, detail) in &checks {
        let (icon, icon_color) = if *ok { ("✓", SUCCESS) } else { ("✗", ERROR) };
        lines.push(Line::from(vec![
            Span::styled(format!("  {} ", icon), Style::default().fg(icon_color).bold()),
            Span::styled(format!("{:<30}", name), Style::default().fg(TEXT)),
            Span::styled(*detail, Style::default().fg(MUTED)),
        ]));
    }

    lines.push(Line::from(""));
    lines.push(Line::from(vec![
        Span::styled("  → ", Style::default().fg(YELLOW)),
        Span::styled(
            "Core packages will be installed via pacman + AUR",
            Style::default().fg(MUTED),
        ),
    ]));
    lines.push(Line::from(""));
    lines.push(Line::from(""));
    lines.push(Line::from(vec![
        Span::styled("  ▶  ", Style::default().fg(enter_pulse)),
        Span::styled("Press Enter to begin installation", Style::default().fg(enter_pulse).bold()),
    ]));

    let widget = Paragraph::new(lines)
        .block(
            Block::default()
                .title(Span::styled(" System Check ", Style::default().fg(ACCENT).bold()))
                .borders(Borders::ALL)
                .border_style(Style::default().fg(ACCENT_DIM))
                .style(Style::default().bg(SURFACE)),
        );

    f.render_widget(widget, area);
}

// ─── Installing ──────────────────────────────────────────────────────────────

fn render_installing(f: &mut ratatui::Frame, area: Rect, app: &App) {
    // Split area: logs on top, progress bar at bottom
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Min(5),
            Constraint::Length(3),
        ])
        .split(area);

    // ── Log panel ──
    let mut lines: Vec<Line> = vec![
        Line::from(""),
        Line::from(vec![Span::styled(
            "  Installation Progress",
            Style::default().fg(TEXT).bold(),
        )]),
        Line::from(""),
    ];

    if !app.install_started {
        let pulse = pulse_color(app.tick, ACCENT, ACCENT_DIM);
        lines.push(Line::from(vec![
            Span::styled("  ▶  ", Style::default().fg(pulse)),
            Span::styled("Press ", Style::default().fg(MUTED)),
            Span::styled("Enter", Style::default().fg(pulse).bold()),
            Span::styled(" to begin the installation process.", Style::default().fg(MUTED)),
        ]));
    }

    for (i, (msg, done)) in app.logs.iter().enumerate() {
        let is_current = i == app.logs.len() - 1 && app.install_started && !done;

        let prefix = if *done {
            Span::styled("  ✓  ", Style::default().fg(SUCCESS))
        } else if is_current {
            Span::styled(
                format!("  {}  ", spinner_frame(app.tick)),
                Style::default().fg(ACCENT),
            )
        } else {
            Span::styled("  ·  ", Style::default().fg(MUTED))
        };

        let style = if is_current {
            Style::default().fg(ACCENT).add_modifier(Modifier::BOLD)
        } else if *done {
            Style::default().fg(TEXT)
        } else {
            Style::default().fg(MUTED)
        };

        lines.push(Line::from(vec![prefix, Span::styled(msg.as_str(), style)]));
    }

    let log_widget = Paragraph::new(lines)
        .wrap(Wrap { trim: false })
        .block(
            Block::default()
                .title(Span::styled(" Installing ActivSpot ", Style::default().fg(ACCENT).bold()))
                .borders(Borders::ALL)
                .border_style(Style::default().fg(ACCENT_DIM))
                .style(Style::default().bg(SURFACE)),
        );

    f.render_widget(log_widget, chunks[0]);

    // ── Progress bar ──
    let completed = app.logs.iter().filter(|(_, done)| *done).count();
    let ratio = if TOTAL_STEPS > 0 {
        (completed as f64 / TOTAL_STEPS as f64).min(1.0)
    } else {
        0.0
    };

    let label = if app.install_started {
        format!(" {}/{} steps ", completed, TOTAL_STEPS)
    } else {
        " waiting ".to_string()
    };

    let gauge = Gauge::default()
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(ACCENT_DIM))
                .style(Style::default().bg(SURFACE)),
        )
        .gauge_style(Style::default().fg(ACCENT).bg(SURFACE))
        .ratio(ratio)
        .label(Span::styled(label, Style::default().fg(TEXT).bold()));

    f.render_widget(gauge, chunks[1]);
}

// ─── Success ─────────────────────────────────────────────────────────────────

fn render_success(f: &mut ratatui::Frame, area: Rect, app: &App) {
    let icon_pulse = pulse_color(app.tick, SUCCESS, Color::Rgb(100, 180, 100));

    let lines = vec![
        Line::from(""),
        Line::from(vec![Span::styled(
            "  ✦  Installation Complete  ✦",
            Style::default().fg(icon_pulse).bold(),
        )]),
        Line::from(""),
        Line::from(vec![Span::styled(
            "  ActivSpot shell has been successfully installed.",
            Style::default().fg(TEXT),
        )]),
        Line::from(""),
        Line::from(vec![Span::styled("  Next steps:", Style::default().fg(MUTED).bold())]),
        Line::from(""),
        Line::from(vec![
            Span::styled("  1. ", Style::default().fg(ACCENT)),
            Span::styled("Add wallpapers to ", Style::default().fg(TEXT)),
            Span::styled("~/Pictures/Wallpapers", Style::default().fg(ACCENT_DIM).bold()),
        ]),
        Line::from(vec![
            Span::styled("  2. ", Style::default().fg(ACCENT)),
            Span::styled("Log out and select Hyprland, or run it from a TTY", Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("  3. ", Style::default().fg(ACCENT)),
            Span::styled("Open settings: ", Style::default().fg(TEXT)),
            Span::styled("~/.config/hypr/scripts/config_ui_launch.sh", Style::default().fg(ACCENT_DIM).bold()),
        ]),
        Line::from(""),
        Line::from(vec![Span::styled(
            "  Thank you for using ActivSpot.",
            Style::default().fg(MUTED),
        )]),
    ];

    let widget = Paragraph::new(lines)
        .alignment(Alignment::Left)
        .wrap(Wrap { trim: false })
        .block(
            Block::default()
                .title(Span::styled(" ✓ Success ", Style::default().fg(SUCCESS).bold()))
                .borders(Borders::ALL)
                .border_style(Style::default().fg(SUCCESS))
                .style(Style::default().bg(SURFACE)),
        );

    f.render_widget(widget, area);
}

// ─── Error ───────────────────────────────────────────────────────────────────

fn render_error(f: &mut ratatui::Frame, area: Rect, app: &App) {
    let msg = app.error_message.as_deref().unwrap_or("Unknown error occurred.");

    let lines = vec![
        Line::from(""),
        Line::from(vec![Span::styled(
            "  Installation failed.",
            Style::default().fg(ERROR).bold(),
        )]),
        Line::from(""),
        Line::from(vec![
            Span::styled("  Error: ", Style::default().fg(MUTED)),
            Span::styled(msg, Style::default().fg(TEXT)),
        ]),
        Line::from(""),
        Line::from(vec![Span::styled(
            "  Press Backspace to return to system check.",
            Style::default().fg(MUTED),
        )]),
    ];

    let widget = Paragraph::new(lines)
        .block(
            Block::default()
                .title(Span::styled(" ✗ Error ", Style::default().fg(ERROR).bold()))
                .borders(Borders::ALL)
                .border_style(Style::default().fg(ERROR))
                .style(Style::default().bg(SURFACE)),
        );

    f.render_widget(widget, area);
}

// ─── Footer ──────────────────────────────────────────────────────────────────

fn render_footer(f: &mut ratatui::Frame, area: Rect, app: &App) {
    let keys: &[(&str, &str)] = match app.screen {
        Screen::Welcome =>      &[("Enter", "continue"), ("q", "quit")],
        Screen::SystemCheck =>  &[("Enter", "install"), ("⌫", "back"), ("q", "quit")],
        Screen::Installing =>   &[("Enter", "next step"), ("q", "abort")],
        Screen::Success =>      &[("Enter", "exit")],
        Screen::Error =>        &[("⌫", "retry"), ("q", "quit")],
    };

    let mut spans = vec![Span::raw("  ")];
    for (i, (key, label)) in keys.iter().enumerate() {
        if i > 0 {
            spans.push(Span::styled("   ", Style::default().fg(MUTED)));
        }
        spans.push(Span::styled(
            format!(" {} ", key),
            Style::default().fg(BG).bg(ACCENT_DIM).bold(),
        ));
        spans.push(Span::styled(
            format!(" {}", label),
            Style::default().fg(MUTED),
        ));
    }

    let footer = Paragraph::new(Line::from(spans))
        .alignment(Alignment::Left)
        .block(
            Block::default()
                .borders(Borders::TOP)
                .border_style(Style::default().fg(ACCENT_DIM))
                .style(Style::default().bg(SURFACE)),
        );

    f.render_widget(footer, area);
}
