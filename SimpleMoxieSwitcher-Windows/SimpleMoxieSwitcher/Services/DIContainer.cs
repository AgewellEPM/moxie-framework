using System;
using System.Collections.Generic;

namespace SimpleMoxieSwitcher.Services
{
    /// <summary>
    /// Simple dependency injection container for managing service instances
    /// </summary>
    public class DIContainer
    {
        private static readonly Lazy<DIContainer> _instance = new(() => new DIContainer());
        private readonly Dictionary<Type, object> _services = new();
        private readonly Dictionary<Type, Func<object>> _factories = new();

        private DIContainer()
        {
            RegisterDefaultServices();
        }

        public static DIContainer Instance => _instance.Value;

        /// <summary>
        /// Register a singleton service instance
        /// </summary>
        public void Register<TInterface>(TInterface implementation) where TInterface : class
        {
            _services[typeof(TInterface)] = implementation;
        }

        /// <summary>
        /// Register a service with a specific implementation type
        /// </summary>
        public void Register<TInterface, TImplementation>()
            where TImplementation : TInterface, new()
            where TInterface : class
        {
            _factories[typeof(TInterface)] = () => new TImplementation();
        }

        /// <summary>
        /// Register a service with a factory function
        /// </summary>
        public void Register<TInterface>(Func<TInterface> factory) where TInterface : class
        {
            _factories[typeof(TInterface)] = () => factory();
        }

        /// <summary>
        /// Resolve a registered service
        /// </summary>
        public TInterface Resolve<TInterface>() where TInterface : class
        {
            var type = typeof(TInterface);

            // Check for existing singleton instance
            if (_services.TryGetValue(type, out var service))
            {
                return (TInterface)service;
            }

            // Check for factory
            if (_factories.TryGetValue(type, out var factory))
            {
                var instance = factory();
                if (instance is TInterface typedInstance)
                {
                    return typedInstance;
                }
            }

            // Try to create a default instance if it's a concrete type
            if (!type.IsInterface && !type.IsAbstract)
            {
                try
                {
                    var instance = Activator.CreateInstance<TInterface>();
                    return instance;
                }
                catch
                {
                    // Ignore and throw not registered exception below
                }
            }

            throw new InvalidOperationException($"Service of type {type.Name} is not registered");
        }

        /// <summary>
        /// Try to resolve a service, returns null if not registered
        /// </summary>
        public TInterface TryResolve<TInterface>() where TInterface : class
        {
            try
            {
                return Resolve<TInterface>();
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Check if a service is registered
        /// </summary>
        public bool IsRegistered<TInterface>() where TInterface : class
        {
            var type = typeof(TInterface);
            return _services.ContainsKey(type) || _factories.ContainsKey(type);
        }

        /// <summary>
        /// Clear all registered services
        /// </summary>
        public void Clear()
        {
            _services.Clear();
            _factories.Clear();
            RegisterDefaultServices();
        }

        /// <summary>
        /// Register default services
        /// </summary>
        private void RegisterDefaultServices()
        {
            // Register core services
            Register<IDockerService, DockerService>();
            Register<IMQTTService, MQTTService>();
            Register<IAIService, AIService>();
            Register<IUsageRepository, UsageRepository>();

            // Register singleton services
            Register<AIProviderManager>(new AIProviderManager());
            Register<ContentFilterService>(new ContentFilterService());
            Register<PersonalityService>(new PersonalityService());
            Register<ConversationService>(new ConversationService());
            Register<MemoryExtractionService>(new MemoryExtractionService());
            Register<MemoryStorageService>(new MemoryStorageService());
            Register<IntentDetectionService>(new IntentDetectionService());
            Register<LocalizationService>(new LocalizationService());
            Register<VocabularyGenerationService>(new VocabularyGenerationService());
            Register<GameContentGenerationService>(new GameContentGenerationService());
            Register<GamesPersistenceService>(new GamesPersistenceService());
            Register<ParentNotificationService>(new ParentNotificationService());
            Register<SafetyLogService>(new SafetyLogService());
            Register<ChildProfileService>(new ChildProfileService());
            Register<PINService>(new PINService());
            Register<PersonalityShiftService>(new PersonalityShiftService());
            Register<ConversationListenerService>(new ConversationListenerService());
            Register<AppearanceService>(new AppearanceService());
            Register<SmartHomeService>(new SmartHomeService());
            Register<QRCodeService>(new QRCodeService());
            Register<DependencyInstallationService>(new DependencyInstallationService());
        }
    }

    // Extension methods for easier usage
    public static class DIContainerExtensions
    {
        /// <summary>
        /// Configure services using a fluent API
        /// </summary>
        public static DIContainer ConfigureServices(this DIContainer container, Action<DIContainer> configure)
        {
            configure(container);
            return container;
        }

        /// <summary>
        /// Register multiple services at once
        /// </summary>
        public static DIContainer RegisterMany(this DIContainer container, params (Type serviceType, object implementation)[] services)
        {
            foreach (var (serviceType, implementation) in services)
            {
                var registerMethod = container.GetType().GetMethod("Register", new[] { implementation.GetType() });
                registerMethod?.MakeGenericMethod(serviceType).Invoke(container, new[] { implementation });
            }
            return container;
        }
    }
}