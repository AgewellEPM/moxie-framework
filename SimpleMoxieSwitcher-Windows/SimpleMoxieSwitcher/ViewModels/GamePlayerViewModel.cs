using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;
using System.Windows.Threading;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.Services;
using SimpleMoxieSwitcher.Services.Interfaces;

namespace SimpleMoxieSwitcher.ViewModels
{
    public class GamePlayerViewModel : INotifyPropertyChanged
    {
        private readonly GameContentGenerationService _gameContentService;
        private readonly DispatcherTimer _delayTimer;

        private GameSession _session;
        private int _currentQuestionIndex = 0;
        private bool _isGameOver = false;
        private string _spellingInput = "";

        // Game-specific questions
        private ObservableCollection<TriviaQuestion> _triviaQuestions = new ObservableCollection<TriviaQuestion>();
        private ObservableCollection<SpellingWord> _spellingWords = new ObservableCollection<SpellingWord>();
        private ObservableCollection<MovieLineChallenge> _movieLineChallenges = new ObservableCollection<MovieLineChallenge>();
        private ObservableCollection<VideoGameChallenge> _videoGameChallenges = new ObservableCollection<VideoGameChallenge>();

        public GameSession Session
        {
            get => _session;
            set
            {
                _session = value;
                OnPropertyChanged();
            }
        }

        public int CurrentQuestionIndex
        {
            get => _currentQuestionIndex;
            set
            {
                _currentQuestionIndex = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(CurrentTriviaQuestion));
                OnPropertyChanged(nameof(CurrentSpellingWord));
                OnPropertyChanged(nameof(CurrentMovieLineChallenge));
                OnPropertyChanged(nameof(CurrentVideoGameChallenge));
            }
        }

        public bool IsGameOver
        {
            get => _isGameOver;
            set
            {
                _isGameOver = value;
                OnPropertyChanged();
            }
        }

        public string SpellingInput
        {
            get => _spellingInput;
            set
            {
                _spellingInput = value;
                OnPropertyChanged();
            }
        }

        public ObservableCollection<TriviaQuestion> TriviaQuestions
        {
            get => _triviaQuestions;
            set
            {
                _triviaQuestions = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(TotalQuestions));
            }
        }

        public ObservableCollection<SpellingWord> SpellingWords
        {
            get => _spellingWords;
            set
            {
                _spellingWords = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(TotalQuestions));
            }
        }

        public ObservableCollection<MovieLineChallenge> MovieLineChallenges
        {
            get => _movieLineChallenges;
            set
            {
                _movieLineChallenges = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(TotalQuestions));
            }
        }

        public ObservableCollection<VideoGameChallenge> VideoGameChallenges
        {
            get => _videoGameChallenges;
            set
            {
                _videoGameChallenges = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(TotalQuestions));
            }
        }

        public int TotalQuestions
        {
            get
            {
                switch (Session?.GameType)
                {
                    case GameSession.GameType.KnowledgeQuest:
                        return 0; // Knowledge Quest uses its own system
                    case GameSession.GameType.Trivia:
                        return TriviaQuestions.Count;
                    case GameSession.GameType.SpellingBee:
                        return SpellingWords.Count;
                    case GameSession.GameType.MovieLines:
                        return MovieLineChallenges.Count;
                    case GameSession.GameType.VideoGames:
                        return VideoGameChallenges.Count;
                    default:
                        return 0;
                }
            }
        }

        public TriviaQuestion CurrentTriviaQuestion
        {
            get
            {
                if (CurrentQuestionIndex < TriviaQuestions.Count)
                    return TriviaQuestions[CurrentQuestionIndex];
                return null;
            }
        }

        public SpellingWord CurrentSpellingWord
        {
            get
            {
                if (CurrentQuestionIndex < SpellingWords.Count)
                    return SpellingWords[CurrentQuestionIndex];
                return null;
            }
        }

        public MovieLineChallenge CurrentMovieLineChallenge
        {
            get
            {
                if (CurrentQuestionIndex < MovieLineChallenges.Count)
                    return MovieLineChallenges[CurrentQuestionIndex];
                return null;
            }
        }

        public VideoGameChallenge CurrentVideoGameChallenge
        {
            get
            {
                if (CurrentQuestionIndex < VideoGameChallenges.Count)
                    return VideoGameChallenges[CurrentQuestionIndex];
                return null;
            }
        }

        // Commands
        public ICommand StartGameCommand { get; }
        public ICommand AnswerTriviaCommand { get; }
        public ICommand SubmitSpellingCommand { get; }
        public ICommand PronounceWordCommand { get; }
        public ICommand AnswerMovieLineCommand { get; }
        public ICommand AnswerVideoGameCommand { get; }
        public ICommand NextQuestionCommand { get; }
        public ICommand PlayAgainCommand { get; }

        public GamePlayerViewModel(GameSession.GameType gameType, GameContentGenerationService gameContentService = null)
        {
            Session = new GameSession(gameType);
            _gameContentService = gameContentService ?? new GameContentGenerationService();
            _delayTimer = new DispatcherTimer();
            _delayTimer.Tick += DelayTimer_Tick;

            // Initialize commands
            StartGameCommand = new RelayCommand(async () => await StartGame());
            AnswerTriviaCommand = new RelayCommand<int>(AnswerTrivia);
            SubmitSpellingCommand = new RelayCommand(SubmitSpelling);
            PronounceWordCommand = new RelayCommand(PronounceWord);
            AnswerMovieLineCommand = new RelayCommand<int>(AnswerMovieLine);
            AnswerVideoGameCommand = new RelayCommand<int>(AnswerVideoGame);
            NextQuestionCommand = new RelayCommand(NextQuestion);
            PlayAgainCommand = new RelayCommand(async () => await PlayAgain());
        }

        public async Task StartGame()
        {
            await GenerateQuestions();
        }

        private async Task GenerateQuestions()
        {
            switch (Session.GameType)
            {
                case GameSession.GameType.KnowledgeQuest:
                    break; // Knowledge Quest uses its own system
                case GameSession.GameType.Trivia:
                    await GenerateTriviaQuestions();
                    break;
                case GameSession.GameType.SpellingBee:
                    await GenerateSpellingWords();
                    break;
                case GameSession.GameType.MovieLines:
                    await GenerateMovieLineChallenges();
                    break;
                case GameSession.GameType.VideoGames:
                    await GenerateVideoGameChallenges();
                    break;
            }
        }

        // Trivia Methods
        private async Task GenerateTriviaQuestions()
        {
            try
            {
                var questions = await _gameContentService.GenerateTriviaQuestions(
                    category: null,
                    difficulty: TriviaQuestion.Difficulty.Medium,
                    count: 10
                );

                TriviaQuestions.Clear();
                foreach (var question in questions)
                {
                    TriviaQuestions.Add(question);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to generate trivia questions: {ex.Message}");
                TriviaQuestions.Clear();
            }
        }

        private void AnswerTrivia(int answerIndex)
        {
            if (CurrentQuestionIndex >= TriviaQuestions.Count) return;

            var question = TriviaQuestions[CurrentQuestionIndex];
            question.UserAnswer = answerIndex;
            Session.QuestionsAnswered++;

            if (question.IsCorrect == true)
            {
                Session.CorrectAnswers++;
                Session.Score += question.Points;
            }

            // Delay before next question
            StartDelayedAction(() => NextQuestion(), TimeSpan.FromSeconds(1.5));
        }

        // Spelling Bee Methods
        private async Task GenerateSpellingWords()
        {
            try
            {
                var words = await _gameContentService.GenerateSpellingWords(
                    gradeLevel: "elementary school",
                    category: null,
                    difficulty: TriviaQuestion.Difficulty.Medium,
                    count: 10
                );

                SpellingWords.Clear();
                foreach (var word in words)
                {
                    SpellingWords.Add(word);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to generate spelling words: {ex.Message}");
                SpellingWords.Clear();
            }
        }

        private void PronounceWord()
        {
            // Placeholder for TTS integration with Moxie's voice system
            var word = CurrentSpellingWord;
            if (word != null)
            {
                System.Diagnostics.Debug.WriteLine($"Pronouncing: {word.Word}");
                // TODO: Integrate with Windows TTS API
            }
        }

        private void SubmitSpelling()
        {
            if (CurrentQuestionIndex >= SpellingWords.Count) return;

            var word = SpellingWords[CurrentQuestionIndex];
            word.UserSpelling = SpellingInput;
            word.Attempts++;
            Session.QuestionsAnswered++;

            if (word.IsCorrect == true)
            {
                Session.CorrectAnswers++;
                Session.Score += word.Points;
                SpellingInput = "";

                // Move to next word after delay
                StartDelayedAction(() => NextQuestion(), TimeSpan.FromSeconds(2.0));
            }
            else
            {
                // Allow retry
                SpellingInput = "";
            }
        }

        // Movie Lines Methods
        private async Task GenerateMovieLineChallenges()
        {
            try
            {
                var challenges = await _gameContentService.GenerateMovieQuotes(
                    genre: null,
                    difficulty: TriviaQuestion.Difficulty.Medium,
                    count: 8
                );

                MovieLineChallenges.Clear();
                foreach (var challenge in challenges)
                {
                    MovieLineChallenges.Add(challenge);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to generate movie line challenges: {ex.Message}");
                MovieLineChallenges.Clear();
            }
        }

        private void AnswerMovieLine(int answerIndex)
        {
            if (CurrentQuestionIndex >= MovieLineChallenges.Count) return;

            var challenge = MovieLineChallenges[CurrentQuestionIndex];
            challenge.UserAnswer = answerIndex;
            Session.QuestionsAnswered++;

            if (challenge.IsCorrect == true)
            {
                Session.CorrectAnswers++;
                Session.Score += challenge.Points;
            }

            StartDelayedAction(() => NextQuestion(), TimeSpan.FromSeconds(1.5));
        }

        // Video Games Methods
        private async Task GenerateVideoGameChallenges()
        {
            try
            {
                var challenges = await _gameContentService.GenerateVideoGameChallenges(
                    category: null,
                    difficulty: TriviaQuestion.Difficulty.Medium,
                    count: 8
                );

                VideoGameChallenges.Clear();
                foreach (var challenge in challenges)
                {
                    VideoGameChallenges.Add(challenge);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to generate video game challenges: {ex.Message}");
                VideoGameChallenges.Clear();
            }
        }

        private void AnswerVideoGame(int answerIndex)
        {
            if (CurrentQuestionIndex >= VideoGameChallenges.Count) return;

            var challenge = VideoGameChallenges[CurrentQuestionIndex];
            challenge.UserAnswer = answerIndex;
            Session.QuestionsAnswered++;

            if (challenge.IsCorrect == true)
            {
                Session.CorrectAnswers++;
                Session.Score += challenge.Points;
            }

            StartDelayedAction(() => NextQuestion(), TimeSpan.FromSeconds(1.5));
        }

        // Game Flow Methods
        private void NextQuestion()
        {
            if (CurrentQuestionIndex < TotalQuestions - 1)
            {
                CurrentQuestionIndex++;
            }
            else
            {
                EndGame();
            }
        }

        private void EndGame()
        {
            Session.IsCompleted = true;
            IsGameOver = true;

            // Save session to database
            Task.Run(async () => await SaveGameSession());
        }

        private async Task PlayAgain()
        {
            // Reset game
            Session = new GameSession(Session.GameType);
            CurrentQuestionIndex = 0;
            IsGameOver = false;
            SpellingInput = "";
            await GenerateQuestions();
        }

        public string GetMoxieMessage()
        {
            var messages = new[]
            {
                "You're doing great! Keep it up!",
                "Nice work! Let's keep going!",
                "Awesome! You're on fire!",
                "Great job! One more question!",
                "You've got this! Stay focused!",
                "Fantastic! Keep that momentum!",
                "Brilliant! Almost there!",
                "Woohoo! You're amazing!"
            };

            var random = new Random();
            return messages[random.Next(messages.Length)];
        }

        public string GetRank()
        {
            var accuracy = Session.Accuracy;
            if (accuracy >= 0.9)
            {
                return "Master";
            }
            else if (accuracy >= 0.7)
            {
                return "Expert";
            }
            else if (accuracy >= 0.5)
            {
                return "Good";
            }
            else
            {
                return "Keep Practicing!";
            }
        }

        // Persistence
        private async Task SaveGameSession()
        {
            var dockerService = DIContainer.Instance.Resolve<IDockerService>();
            var persistenceService = new GamesPersistenceService(dockerService);

            try
            {
                await persistenceService.RecordGameSession(Session);
                System.Diagnostics.Debug.WriteLine("Game session saved successfully");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to save game session: {ex.Message}");
            }
        }

        // Helper methods
        private void StartDelayedAction(Action action, TimeSpan delay)
        {
            _delayTimer.Stop();
            _delayTimer.Interval = delay;
            _delayTimer.Tag = action;
            _delayTimer.Start();
        }

        private void DelayTimer_Tick(object sender, EventArgs e)
        {
            _delayTimer.Stop();
            if (_delayTimer.Tag is Action action)
            {
                action.Invoke();
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    // RelayCommand helper
    public class RelayCommand : ICommand
    {
        private readonly Action _execute;
        private readonly Func<bool> _canExecute;

        public RelayCommand(Action execute, Func<bool> canExecute = null)
        {
            _execute = execute;
            _canExecute = canExecute;
        }

        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter) => _canExecute?.Invoke() ?? true;

        public void Execute(object parameter) => _execute();
    }

    public class RelayCommand<T> : ICommand
    {
        private readonly Action<T> _execute;
        private readonly Func<T, bool> _canExecute;

        public RelayCommand(Action<T> execute, Func<T, bool> canExecute = null)
        {
            _execute = execute;
            _canExecute = canExecute;
        }

        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            if (parameter is T typedParam)
                return _canExecute?.Invoke(typedParam) ?? true;
            return false;
        }

        public void Execute(object parameter)
        {
            if (parameter is T typedParam)
                _execute(typedParam);
        }
    }
}