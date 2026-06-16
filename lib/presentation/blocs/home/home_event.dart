part of 'home_bloc.dart';

sealed class HomeEvent {}

class HomeLoadRequested extends HomeEvent {}

class HomeSyncRequested extends HomeEvent {}

class HomeTopUpRequested extends HomeEvent {
  final double amount;
  HomeTopUpRequested(this.amount);
}

class HomeLogoutRequested extends HomeEvent {}
