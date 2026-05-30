import { getPerformance, trace } from 'firebase/performance';
import { getAnalytics, logEvent } from 'firebase/analytics';

class PerformanceMonitor {
  private static instance: PerformanceMonitor;
  private performance;
  private analytics;

  private constructor() {
    this.performance = getPerformance();
    this.analytics = getAnalytics();
  }

  public static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor();
    }
    return PerformanceMonitor.instance;
  }

  public startTrace(traceName: string) {
    return trace(this.performance, traceName);
  }

  public logPageView(pageName: string) {
    logEvent(this.analytics, 'page_view', {
      page_title: pageName,
      page_location: window.location.href,
      page_path: window.location.pathname
    });
  }

  public logError(error: Error, context?: string) {
    logEvent(this.analytics, 'error', {
      error_name: error.name,
      error_message: error.message,
      error_stack: error.stack,
      context: context || 'unknown'
    });
  }

  public logUserAction(action: string, details?: Record<string, any>) {
    logEvent(this.analytics, 'user_action', {
      action_name: action,
      ...details
    });
  }

  public async measureAsyncOperation<T>(
    operationName: string,
    operation: () => Promise<T>
  ): Promise<T> {
    const perfTrace = this.startTrace(operationName);
    try {
      perfTrace.start();
      const result = await operation();
      perfTrace.stop();
      return result;
    } catch (error) {
      perfTrace.stop();
      throw error;
    }
  }

  public measureSyncOperation<T>(
    operationName: string,
    operation: () => T
  ): T {
    const perfTrace = this.startTrace(operationName);
    try {
      perfTrace.start();
      const result = operation();
      perfTrace.stop();
      return result;
    } catch (error) {
      perfTrace.stop();
      throw error;
    }
  }
}

export const performanceMonitor = PerformanceMonitor.getInstance();

// HOC for component performance monitoring
export const withPerformanceTracking = <P extends object>(
  WrappedComponent: React.ComponentType<P>,
  componentName: string
) => {
  return class WithPerformanceTracking extends React.Component<P> {
    private mountTrace;

    constructor(props: P) {
      super(props);
      this.mountTrace = performanceMonitor.startTrace(`${componentName}_mount`);
    }

    componentDidMount() {
      this.mountTrace.stop();
      performanceMonitor.logPageView(componentName);
    }

    componentDidCatch(error: Error) {
      performanceMonitor.logError(error, componentName);
    }

    render() {
      return <WrappedComponent {...this.props} />;
    }
  };
}; 